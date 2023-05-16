import glob
from collections import defaultdict

from luadoc import FilesProcessor, DocOptions
from luadoc.model import LuaClass, LuaVisibility

# Ignore some irrelevant or private classes
blacklist = {
    "DreamVec2",
    "DreamVec3",
    "DreamVec4",
    "DreamMat2",
    "DreamMat3",
    "DreamMat4",
    "DreamQuat",
    "DreamClonable",
    "DreamHasShaders",
    "DreamTransformable",
    "DreamScene",
    "DreamTask",
    "DreamIsNamed",
    "",
    "DreamMaterializedText",
    "DreamCodepointMaterial",
    "DreamIndexedCodepointMaterial",
    "DreamMaterializedCodepoints",
    "DreamGlyph",
}

lookup = {
    "Animation": "Animations",
    "AnimationFrame": "Animations",
    "Bone": "Animations",
    "Pose": "Animations",
    "Skeleton": "Animations",
    #
    "Mesh": "Meshes",
    "InstancedMesh": "Meshes",
    "MeshBuilder": "Meshes",
    "MutableMeshBuilder": "Meshes",
    "Sprite": "Meshes",
    "SpriteBatch": "Meshes",
    "TextMeshBuilder": "Meshes",
    #
    "CollisionMesh": "Extensions",
    "RaytraceMesh": "Extensions",
}

groups = [
    "Objects",
    "Meshes",
    "Animations",
    "Extensions",
]

group_descriptions = {
    "Objects": "General classes.",
    "Meshes": "Different drawable meshes.",
    "Animations": "Classes required to animated skeletons.",
    "Extensions": "Classes intended to be used by certain extensions.",
}

special_constructors = {
    "loadObject": "DreamObject",
    "loadLibrary": "DreamObject",
    "newDynamicBuffer": "DreamBuffer",
}


def get_name(n):
    if n == "Dream":
        return n
    return n[5:]


def get_type(n):
    if n.id == "custom" and n.name.startswith("Dream"):
        return get_link(n.name)
    if n.id == "custom":
        return n.name
    if n.id == "dict":
        return f"<{get_type(n.key_type)}, {get_type(n.value_type)}>"
    if n.id == "array":
        return f"{get_type(n.type)}[]"
    if n.id == "or":
        return ", ".join([get_type(t) for t in n.types])
    return n.id


def get_link(n):
    if n in blacklist:
        return get_name(n)

    return f"[{get_name(n)}](https://3dreamengine.github.io/3DreamEngine/docu/classes/{get_name(n).lower()})"


def unique(old):
    l2 = []
    for v in old:
        if v not in l2:
            l2.append(v)
    return l2


def populate_method(c, m, file):
    file.append(
        f"### `{get_name(c.name)}{'.' if m.is_static else ':'}{m.name}({', '.join(unique([p.name for p in m.params]))})`"
    )
    if m.is_deprecated:
        file.append("`deprecated`  ")
    if m.is_static:
        file.append("`static`  ")

    file.append(m.short_desc)
    if len(m.params) > 0:
        file.append(f"#### Arguments")
        for p in m.params:
            file.append(f"`{p.name}` ({get_type(p.type)}) {p.desc}\n")

    if len(m.returns) > 0:
        file.append(f"#### Returns")
        for p in m.returns:
            file.append(f"({get_type(p.type)}) {p.desc}\n")
    file.append("\n_________________\n")


def populate_methods(classes, c, file):
    for m in c.methods:
        if m.visibility == LuaVisibility.PUBLIC:
            populate_method(c, m, file)

    for h in c.inherits_from:
        populate_methods(classes, classes[h], file)


def get_constructors(classes, c):
    constructors = []
    for m in classes["Dream"].methods:
        if (
            m.name == "new" + get_name(c.name)
            or m.name in special_constructors
            and special_constructors[m.name] == c.name
        ):
            constructors.append(m)
    return constructors


def process_class(classes, c):
    file = ["# " + get_name(c.name)]

    # Super classes
    if c.inherits_from:
        file.append(f"Extends {', '.join(f'{get_link(n)}' for n in c.inherits_from)}\n")

    # Description
    file.append(c.desc)

    # Constructors
    constructors = get_constructors(classes, c)
    if len(constructors) > 0:
        file.append("## Constructors")
        for m in constructors:
            populate_method(c, m, file)

    # Fields
    if len(c.fields) > 0:
        file.append("## Fields")
        for m in c.fields:
            if m.visibility == LuaVisibility.PUBLIC:
                file.append(f"`{m.name}` ({get_type(m.type)}) {m.desc}\n")

    # Methods
    if len(c.methods) > 0:
        file.append("## Methods")
        populate_methods(classes, c, file)

    # Save
    with open("../docu/classes/" + get_name(c.name).lower() + ".md", "w") as f:
        f.write("\n".join(file))


def main():
    # List files
    files = glob.glob("../3DreamEngine/**/*.lua", recursive=True)

    # Parse doc annotations
    models = FilesProcessor(12, DocOptions()).run(files)

    models = sorted(models, key=lambda x: x.file_path)

    classes = defaultdict(lambda: LuaClass())

    # Merge classes as they may be spread across files
    for model in models:
        for c in model.classes:
            if c.name == "lib":
                c.name = "Dream"
            classes[c.name].name = c.name
            classes[c.name].desc += c.short_desc
            classes[c.name].fields += c.fields
            classes[c.name].methods += c.methods
            classes[c.name].inherits_from += c.inherits_from

    # Keep a list of relevant files for the index
    clean_classes = []

    for c in classes.values():
        if c.name.startswith("Dream") and c.name not in blacklist:
            process_class(classes, c)

            if c.name != "Dream":
                clean_classes.append(c.name)

    # Construct new index page
    with open("../index.md", "r") as f:
        old_index = f.read()

    lines = []
    for group in groups:
        lines.append("### " + group)
        lines.append(group_descriptions[group])
        for c in sorted(clean_classes):
            if (lookup[get_name(c)] if get_name(c) in lookup else "Objects") == group:
                lines.append("* " + get_link(c))
        lines.append("")

    index = old_index.find("## Documentation")
    until_index = old_index.find("\n## Extensions", index + 10)
    old_index = "\n".join(
        [
            old_index[: index - 1],
            "## Documentation",
            get_link("Dream"),
            "\n",
        ]
        + lines
        + [
            "",
            old_index[until_index:],
        ]
    )

    with open("../index.md", "w") as f:
        f.write(old_index)


if __name__ == "__main__":
    main()
