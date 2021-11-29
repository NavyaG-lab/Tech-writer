---
owner: "#foundation-tribe"
eleventyExcludeFromCollections: true
---

# Owners

<label>Select an owner:</label>
<select id='owner-options'></select>
<ul id='pages'></ul>
<script>
(function() {
  const mountUrl = function(owner) {
    const requestData = {
      'size': 1000,
      'query': {
        'bool': {
          'must': {
            'term': { 'owner': owner }
          }
        }
      }
    }
    const url = new URL('https://' + 'vpc-prod-global-b-docs-es-xzeygqiyqkzbdxwdqegtrft6pe.sa-east-1.es.amazonaws.com/playbooks/_search');
    url.searchParams.append(
      'filter_path',
      'hits.hits._source.title,hits.hits._source.path'
    );
    url.searchParams.append('source', JSON.stringify(requestData));
    url.searchParams.append('source_content_type', 'application/json');
    return url.toString();
  };
  const pagesList = document.getElementById('pages');
  document
    .getElementById('owner-options')
    .addEventListener('change', function(e) {
        const url = mountUrl(e.target.value);
        fetch(url.toString(), {
          headers: {'Content-Type': 'application/json'}
        }).then(function(response) {
          return response.json();
        }).then(function(json) {
          return json.hits.hits;
        }).then(function(json) {
          const pages = json.map(function(page) {
            return '<li><a href="' + page._source.path + '">' + page._source.title + '</a></li>';
          });
          history.pushState({}, '', '/_pages/owners/?owner=' + encodeURIComponent(e.target.value));
          pagesList.innerHTML = pages.join('');
        });
    });
})();
</script>
<script>
(function() {
  const requestData = {
      'aggs' : {
          'owners' : {
              'terms' : {
                  'field' : 'owner',
                  'order' : { '_key' : 'asc' },
                  'size':10000
              }
          }
      },
      'size' : 0
  };
  const url = new URL('https://' + 'vpc-prod-global-b-docs-es-xzeygqiyqkzbdxwdqegtrft6pe.sa-east-1.es.amazonaws.com' + '/playbooks/_search');
  url.searchParams.append(
    'filter_path',
    'aggregations.owners.buckets.key'
  );
  url.searchParams.append('source', JSON.stringify(requestData));
  url.searchParams.append('source_content_type', 'application/json');
  fetch(url.toString(), {
    headers: {'Content-Type': 'application/json'}
  }).then(function(response) {
    return response.json();
  }).then(function(json) {
    return json.aggregations.owners.buckets;
  }).then(function(owners) {
    const options = owners.map(function(owner) {
        return '<option value=' + owner.key + '>' + owner.key + '</option>'
    });
    const select = document.getElementById('owner-options');
    select.insertAdjacentHTML('afterbegin', options.join(''));
    const initialOwner = new URLSearchParams(document.location.search).get('owner');
    if(initialOwner) {
      select.value = initialOwner;
    }
    select.dispatchEvent(new Event("change"));
  });
})();
</script>
