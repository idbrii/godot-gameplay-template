
static func remove_if(t: Array, should_remove_fn: Callable):
    for i in range(t.size() - 1, -1, -1):
        if should_remove_fn.call(t[i]):
            t.remove_at(i)


# A rough and untested port of [a lua implementation](https://stackoverflow.com/a/53038524/79125).
static func remove_if_untested(t: Array, should_remove_fn: Callable):
    var n = t.size()
    var keep = 0

    for i in range(n):
        if should_remove_fn.call(t[i], i, keep):
            t[i] = null
        else:
            # To keep i, move it into keep's position unless it's already there.
            if i != keep:
                t[keep] = t[i]
                t[i] = null
            keep += 1 # Increment position of where we'll place the next kept value.

    # Remove the nulls
    for i in range(keep, n):
        t.remove_at(i)

    return t
