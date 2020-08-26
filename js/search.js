(function () {
    const urlParams = new URLSearchParams(window.location.search);
    const query = urlParams.get('q');

    if (query) {
        const input = document.querySelector('.md-search__input');
        input.value = query;
        input.focus();
        const event = document.createEvent('Event');
        event.initEvent('input', true, true);
        
        input.dispatchEvent(event);
    }
})();
