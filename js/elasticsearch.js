(function () {
    /**
     * General functions
     */
    let debounceTimeout;

    const debounceFn = (data, fn) => {
        clearTimeout(debounceTimeout);
        debounceTimeout = setTimeout(fn, 500, data);
    };

    const mountUrl = query => {

        const requestData = { "size": 100, "query": { "bool": { "should": { "multi_match": { "query": query, "fuzziness": 1, "fields": ["title^10", "metadata.owner", "content^5"] } } } }, "highlight": { "number_of_fragments": 1, "fragment_size": 150, "tags_schema": "styled", "fields": { "title": {}, "content": {}, "metadata.owner": {} } } };

        const url = new URL(`https://vpc-prod-global-b-docs-es-xzeygqiyqkzbdxwdqegtrft6pe.sa-east-1.es.amazonaws.com/data-platform-docs/_search`);
        url.searchParams.append(
            'filter_path',
            'hits.hits._score,hits.hits._source,hits.hits.matched_queries,hits.hits.highlight,hits.total.value'
        );
        url.searchParams.append('source', JSON.stringify(requestData));
        url.searchParams.append('source_content_type', 'application/json');

        return url.toString();
    }

    /**
     * Manipulating Data
     */
    const handleData = (data) => {
        return data.hits.hits.map((item) => ({
            title: item.highlight?.title?.[0] || item._source.title,
            content: item.highlight?.content?.[0] || item._source.content.substring(0, 150),
            link: item._source.path
        }));
    };


    /**
     * Manipulating DOM
     */
    const showOrHide = (show, element) => {
        show ? element.classList.remove('hidden') : element.classList.add('hidden');
    };

    const showLoading = (show) => {
        const loading = document.querySelector('.md-search-result__meta.loading');
        showOrHide(show, loading);
    };

    const showNoResultsMessage = (show) => {
        const message = document.querySelector('.md-search-result__meta.no-results');
        showOrHide(show, message);
    };

    const showErrorMessage = (show) => {
        const message = document.querySelector('.md-search-result__meta.error');
        showOrHide(show, message);
    };

    const emptyResultList = () => {
        showNoResultsMessage(false);
        showErrorMessage(false);
        document.querySelector('.md-search-result__list').innerHTML = '';
    };

    const listResults = (results) => {
        const resultList = document.querySelector('.md-search-result__list');

        const template = results.map((result) => `
        <li class='md-search-result__item'>
            <a class='md-search-result__link' href='${result.link}'>
                <article class='md-search-result__article md-search-result__article--document'>
                    <h1 class='md-search-result__title'>${result.title}</h1>
                    <p class='md-search-result__teaser'>${result.content}</p>
                </article>
            </a>
        </li>`);

        resultList.innerHTML = template.join('');
    };

    const search = (e) => {
        emptyResultList();

        const query = e.target.value.trim();
        if (!query) {
            return;
        }

        showLoading(true);

        const url = mountUrl(query);

        fetch(url, {
            headers: {
                'Content-Type': 'application/json'
            }
        })
            .then((response) => {
                if (response.ok) {
                    return response.json();
                }
                throw response;
            })
            .then((data) => {
                if (data.hits.total.value === 0) {
                    showNoResultsMessage(true);
                    return;
                }

                const results = handleData(data);
                listResults(results);
            })
            .catch((error) => {
                console.error(error);
                showErrorMessage(true);
            })
            .finally(() => {
                showLoading(false);
            });
    };

    let searchInput = document.querySelector('.md-search__input');

    searchInput.addEventListener('input', (e) => {
        debounceFn(e, search);
    });
})()
