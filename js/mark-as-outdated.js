var elements = document.querySelectorAll("article.md-content__inner > *:not(h1):not(.user-feedback):not(.md-content__button):not(hr):not(.md-source-date):not(.admonition):not(details):not(.mermaid):not(.notebook-content)");
var owner = document.querySelector(".md-source-date.disclaimer").lastElementChild.textContent.replace("Maintained by", "").trim();
var elementsSize = elements.length;

for (var i = 0; i < elementsSize; i++) {
    var element = elements[i];
    var encodedElement = element.textContent.trim();
    var outdatedButton = document.createElement("a");
    outdatedButton.textContent = "feedback";
    outdatedButton.title = "Mark as outdated";
    outdatedButton.setAttribute("aria-label", "Mark as outdated");
    outdatedButton.classList.add("outdated-button", "material-icons", "icon-image-preview");
    outdatedButton.target = "_blank";

    var url = new URL("https://docs.google.com/forms/d/e/1FAIpQLSdMBV30VeGARm5S0K8OKt6gKIDHxhdrIvuna94weXdXa6V4RQ/viewform?usp=pp_url");
    url.searchParams.append("entry.754181246", encodedElement);
    url.searchParams.append("entry.367407502", owner);
    url.searchParams.append("entry.766374219", window.location.href);

    outdatedButton.href = url.toString();
    element.appendChild(outdatedButton);
    element.classList.add("document-symbol");
    outdatedButton.insertAdjacentHTML('afterend', '<div class="overlay"><div>')
}
