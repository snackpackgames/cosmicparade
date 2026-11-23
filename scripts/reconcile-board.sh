#!/bin/bash
# scripts/reconcile-board.sh — Reconcile the `Cosmic Parade v1.0` board with GitHub.
#
# Part of merge housekeeping (documentation/agents/afk-pipeline.md → Merge
# housekeeping). The scheduled routine runs in a cloud session and cannot touch
# Projects v2 at all, so every PR it opens arrives on the board late or not at
# all, and every issue it closes keeps whatever Status it had. This fixes both.
#
# Prints a plan and exits. Pass --apply to actually write.
#
#   bash scripts/reconcile-board.sh              # what would change
#   bash scripts/reconcile-board.sh --apply      # change it
#
# Needs the `project` token scope: gh auth refresh -s project
#
# Only unambiguous drift is corrected, so this is safe to run at any time:
#
#   closed issue, merged/closed PR, Status != Done  ->  Done
#   open issue with open blockers, Status != Blocked  ->  Blocked
#   open issue, no open blockers, Status Blocked      ->  Todo
#   open issue, Status unset (never placed)           ->  Todo
#   recently merged PR absent from the board         ->  added, set Done
#
# Open PRs are never touched: an open PR is `In Progress` by convention and
# nothing here can tell "awaiting review" from "still being written". An open,
# unblocked issue already sitting in Todo or In Progress is left alone too —
# for one of those, only Blocked is a provably wrong Status.
#
# An unset Status is corrected, because it is not a position on the board at
# all: it means nobody has placed the issue, which is what every freshly filed
# issue looks like. Todo is where an unplaced issue belongs, and a blocked one
# never reaches this rule — the Blocked test above is the stronger statement
# and runs first.
#
# Only PRs merged within the last RECENT_DAYS days are added, because this is
# housekeeping for the merge that just happened, not a backfill: the board has
# never held most of the pre-pipeline history, and putting it there now would
# bury the live work. Widen it with --days N to place an older merge.

set -uo pipefail

OWNER=snackpackgames
REPO=cosmicparade
PROJECT_NUMBER=2
RECENT_DAYS=7

APPLY=0
while [[ $# -gt 0 ]]; do
	case "$1" in
		--apply) APPLY=1; shift ;;
		--days)
			[[ "${2:-}" =~ ^[0-9]+$ ]] || { echo "--days needs a number" >&2; exit 2; }
			RECENT_DAYS="$2"; shift 2 ;;
		*) echo "usage: $(basename "$0") [--apply] [--days N]" >&2; exit 2 ;;
	esac
done

command -v gh >/dev/null || { echo "ERROR: gh is not installed." >&2; exit 1; }

# Resolve project, field and option ids fresh. CONTRIBUTING.md is explicit that
# these are not stable across repos, and a stale hardcoded id writes to the
# wrong field rather than failing loudly.
read -r PROJECT_ID STATUS_FIELD_ID < <(
	gh api graphql -f owner="$OWNER" -F number="$PROJECT_NUMBER" -f query='
		query($owner:String!,$number:Int!){
			organization(login:$owner){
				projectV2(number:$number){
					id
					field(name:"Status"){... on ProjectV2SingleSelectField{id}}
				}
			}
		}' --jq '[.data.organization.projectV2.id,
		          .data.organization.projectV2.field.id] | @tsv'
) || { echo "ERROR: could not read project $PROJECT_NUMBER." >&2; exit 1; }

if [[ -z "$PROJECT_ID" || -z "$STATUS_FIELD_ID" || "$PROJECT_ID" == "null" ]]; then
	echo "ERROR: project $PROJECT_NUMBER has no id or no Status field." >&2
	exit 1
fi

declare -A OPTION
while IFS=$'\t' read -r name id; do
	OPTION["$name"]="$id"
done < <(
	gh api graphql -f owner="$OWNER" -F number="$PROJECT_NUMBER" -f query='
		query($owner:String!,$number:Int!){
			organization(login:$owner){
				projectV2(number:$number){
					field(name:"Status"){
						... on ProjectV2SingleSelectField{options{name id}}
					}
				}
			}
		}' --jq '.data.organization.projectV2.field.options[] | [.name,.id] | @tsv'
)

for want in Todo "In Progress" Blocked Done; do
	[[ -n "${OPTION[$want]:-}" ]] || {
		echo "ERROR: Status field has no '$want' option." >&2; exit 1; }
done

# Every board item, paged. One row per item: item-id, type, number, state, Status.
items_tsv() {
	local cursor=""
	while :; do
		local page cursor_arg
		# -F parses a bare `null` as JSON null; -f would send the string "null",
		# which GraphQL rejects as an invalid cursor.
		if [[ -z "$cursor" ]]; then cursor_arg=(-F cursor=null)
		else cursor_arg=(-f "cursor=$cursor"); fi
		page=$(gh api graphql -f owner="$OWNER" -F number="$PROJECT_NUMBER" \
			"${cursor_arg[@]}" -f query='
			query($owner:String!,$number:Int!,$cursor:String){
				organization(login:$owner){
					projectV2(number:$number){
						items(first:100, after:$cursor){
							pageInfo{hasNextPage endCursor}
							nodes{
								id
								content{
									__typename
									... on Issue{number state}
									... on PullRequest{number state}
								}
								fieldValueByName(name:"Status"){
									... on ProjectV2ItemFieldSingleSelectValue{name}
								}
							}
						}
					}
				}
			}')
		if [[ -z "$page" ]]; then
			echo "ERROR: could not read board items." >&2
			return 1
		fi
		jq -r '.data.organization.projectV2.items.nodes[]
			| select(.content.number != null)
			| [.id, .content.__typename, (.content.number|tostring),
			   .content.state, (.fieldValueByName.name // "")] | @tsv' <<<"$page"
		[[ "$(jq -r '.data.organization.projectV2.items.pageInfo.hasNextPage' <<<"$page")" == "true" ]] || return 0
		cursor=$(jq -r '.data.organization.projectV2.items.pageInfo.endCursor' <<<"$page")
	done
}

set_status() { # item-id  status-name
	gh api graphql -f project="$PROJECT_ID" -f item="$1" -f field="$STATUS_FIELD_ID" \
		-f value="${OPTION[$2]}" -f query='
		mutation($project:ID!,$item:ID!,$field:ID!,$value:String!){
			updateProjectV2ItemFieldValue(input:{
				projectId:$project, itemId:$item, fieldId:$field,
				value:{singleSelectOptionId:$value}
			}){projectV2Item{id}}
		}' >/dev/null
}

open_blockers() { # issue-number -> count of OPEN blocking issues
	gh api "repos/$OWNER/$REPO/issues/$1/dependencies/blocked_by" \
		--jq '[.[] | select(.state == "open")] | length' 2>/dev/null || echo 0
}

changes=0
on_board=""

echo "Reconciling $OWNER/$REPO board #$PROJECT_NUMBER"
[[ $APPLY -eq 0 ]] && echo "(dry run — pass --apply to write)"
echo

while IFS=$'\t' read -r item type number state status; do
	on_board+=" $number:$type"
	want=""
	case "$type" in
		PullRequest)
			# MERGED and CLOSED are both terminal; an open PR is left alone.
			[[ "$state" == "OPEN" ]] && continue
			want=Done
			;;
		Issue)
			if [[ "$state" == "CLOSED" ]]; then
				want=Done
			elif [[ "$(open_blockers "$number")" -gt 0 ]]; then
				want=Blocked
			elif [[ "$status" == "Blocked" || -z "$status" ]]; then
				want=Todo
			else
				continue
			fi
			;;
		*) continue ;;
	esac

	[[ "$status" == "$want" ]] && continue
	printf '  %-11s #%-4s %-8s %-13s -> %s\n' \
		"$type" "$number" "$state" "${status:-<unset>}" "$want"
	changes=$((changes + 1))
	[[ $APPLY -eq 1 ]] && { set_status "$item" "$want" || echo "    FAILED to set #$number" >&2; }
done < <(items_tsv)

# Merged PRs the cloud routine never managed to add.
while read -r number; do
	[[ " $on_board " == *" $number:PullRequest "* ]] && continue
	printf '  %-11s #%-4s %-8s %-13s -> added, Done\n' \
		"PullRequest" "$number" "MERGED" "<not on board>"
	changes=$((changes + 1))
	if [[ $APPLY -eq 1 ]]; then
		gh pr edit "$number" --add-project "Cosmic Parade v1.0" >/dev/null 2>&1
		sleep 2
		item=$(gh api graphql -f owner="$OWNER" -f repo="$REPO" -F number="$number" \
			-f query='
			query($owner:String!,$repo:String!,$number:Int!){
				repository(owner:$owner,name:$repo){
					pullRequest(number:$number){
						projectItems(first:10){nodes{id project{number}}}
					}
				}
			}' --jq '.data.repository.pullRequest.projectItems.nodes[]
			         | select(.project.number == '"$PROJECT_NUMBER"') | .id')
		if [[ -n "$item" ]]; then
			set_status "$item" Done || echo "    FAILED to set #$number" >&2
		else
			echo "    FAILED to add #$number to the board" >&2
		fi
	fi
done < <(
	cutoff=$(date -u -d "$RECENT_DAYS days ago" +%Y-%m-%dT%H:%M:%SZ)
	gh api "repos/$OWNER/$REPO/pulls?state=closed&per_page=100&sort=updated&direction=desc" \
		--jq '.[] | select(.merged_at != null and .merged_at > "'"$cutoff"'") | .number'
)

echo
if [[ $changes -eq 0 ]]; then
	echo "Board matches GitHub. Nothing to do."
elif [[ $APPLY -eq 1 ]]; then
	echo "Applied $changes change(s)."
else
	echo "$changes change(s) pending. Re-run with --apply to write them."
fi
