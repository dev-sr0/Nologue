tool
extends EditorPlugin

func _enter_tree():
    add_custom_type("Nologue", "Control", preload("nologue.gd"), preload("icon.png"))

func _exit_tree():
    # Clean-up of the plugin goes here
    # Always remember to remove it from the engine when deactivated
    remove_custom_type("Nologue")

