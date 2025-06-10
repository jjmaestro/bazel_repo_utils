"""utils.bzl"""

def _get_dupes(list_):
    set_ = {}
    dupes = []

    for value in list_:
        if value in set_:
            dupes.append(value)
        set_[value] = True
    return dupes

def _replace_in_place(d, k_replace, replacement, _fail = fail):
    """
    Replace a dict key with one or more k-v.
    """
    if k_replace not in d:
        return _fail("Key to replace not found: {}".format(k_replace))

    if not replacement:
        return _fail("Replacement empty, to delete a key use .pop()")

    res = {}

    for k, v in d.items():
        if k != k_replace:
            res[k] = v
            continue

        for kr, vr in replacement.items():
            res[kr] = vr

    return res

utils = struct(
    get_dupes = _get_dupes,
    replace_in_place = _replace_in_place,
)
