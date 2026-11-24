class_name EffectMatch
extends RefCounted
## One entry firing on one hex: which entry it was, the domains it consumed, the effect it
## produced, and the intensity that effect is shown at.
## https://github.com/snackpackgames/cosmicparade/issues/110
## https://github.com/snackpackgames/cosmicparade/issues/113

## The entry's index in the authored file. Ties break on that order, so "why did this entry win
## here" is answerable only when the index survives into the answer.
var entry_index: int
var domains: Array[int] = []
var effect: InfluenceEffect
## The depth this effect is amplified by: the maximum depth among `domains`, which is the same max
## rule height applies, asked of a narrower set.
var intensity: int
## Which of `domains` set the intensity. Ties go to the lowest `Domain.Kind` value, so the probe's
## text is stable.
var intensity_domain: Domain.Kind
