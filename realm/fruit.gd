class_name Fruit
extends GameData
## One authored fruit: a name and the single domain it carries. A placeholder, the way the
## authored furniture is — growing fruit is M2/M4 and what an offering buys is M4. All that is
## decided here is that an offering carries exactly one domain, and that a shrine holding one
## projects that domain and no other.
## https://github.com/snackpackgames/cosmicparade/issues/75

@export var fruit_name: String = ""
@export var domain: Domain.Kind = Domain.Kind.FOREST
