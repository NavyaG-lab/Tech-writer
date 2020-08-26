document.querySelectorAll('.md-content ol[start]').forEach(list => {
    list.style="counter-reset: item " + list.start + "; counter-increment: item -1;"
});
