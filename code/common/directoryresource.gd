@tool
extends Resource
class_name DirectoryResource
## A resource that loads all of the files in a directory, to reference at
## runtime without searching the filesystem.
## Storing them in a resource makes it easier to setup dependencies for
## build stripping: add this resource to a scene and now all of its resources will
## get included. And walking the filesystem often fails in builds because
## assets are replaced with ".remap" files.

## Check to force a refresh of the loaded resources. Not a real value.
@export var trigger_refresh: bool:
    get:
        return false
    set(value):
        if target_directory:
            _load_resources()
        # else might be loading or otherwise invalid.

## The absolute folder path to load resources from.
## Example: res://scenes/blah/
@export var target_directory := ""

## Limit to files with this extension (no leading period).
@export var file_extension_filter := ""

## Exclude .import metadata files. (Usually you want the asset they correspond to.)
@export var exclude_dot_import := true

## The resources found in target_directory. Click "Trigger Refresh" to refresh
## this list.
@export var resources: Array[Resource]


## Returns recursive listing of files at input path.
##
## If calling at runtime, you must remove .remap:
##   file_path = file_path.replace(".remap", "")
static func get_all_files(
    path: String,
    file_ext := "",
    ignore_import := true,
    files: Array[String] = [],
) -> Array[String]:
    # Source - https://gist.github.com/hiulit/772b8784436898fd7f942750ad99e33e
    if file_ext.begins_with("."):
        # Remove initial dot to match get_extension. Example: ".tscn" -> "tscn"
        file_ext = file_ext.substr(1, file_ext.length() - 1)

    var dir := DirAccess.open(path)
    if DirAccess.get_open_error() == OK:
        dir.list_dir_begin()

        var file_name = dir.get_next()
        while file_name:
            var abs_path = dir.get_current_dir() + "/" + file_name
            if dir.current_is_dir():
                if file_name.begins_with("."):
                    prints("get_all_files: Skipping dot directory:", abs_path)
                else:
                    # recursion!
                    files = get_all_files(abs_path, file_ext, ignore_import, files)
            else:
                if (
                    (file_ext and file_name.get_extension() != file_ext)
                    or (ignore_import and file_name.get_extension() == "import")
                ):
                    #~ prints("get_all_files: Skipping path due to extension:", file_ext, abs_path)
                    file_name = dir.get_next()
                    continue

                files.append(abs_path)

            file_name = dir.get_next()

    else:
        prints("get_all_files: Failed to access path:", path)

    return files


## Loads and returns all Resources at input path. Only works for paths inside a
## Godot project (not from user disk).
static func load_resources_in_path(
    path: String,
    extension_filter: String = "",
    ignore_import := true,
) -> Array[Resource]:
    var files = get_all_files(path, extension_filter, ignore_import)
    var loaded: Array[Resource] = []
    for f in files:
        var r = load(f) as Resource
        if r:
            loaded.append(r)
    return loaded


# Populating automatically in _ready doesn't happen consistently enough to
# support. Must trigger population manually instead.
#func _ready():
#    if not Engine.is_editor_hint():
#        return
#    _load_resources()


func _load_resources():
    resources = load_resources_in_path(target_directory, file_extension_filter, exclude_dot_import)
