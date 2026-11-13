// tdg's search: a box in the docs' sidebar that searches the site's index (_tdg/search.json, which tdg writes
// when it builds the site) for pages with every word typed, best matches first.
const here = new URL(".", import.meta.url);  // _tdg/
const root = new URL("..", here);
let index = null;

async function load() {
  if (!index) index = fetch(new URL("search.json", here)).then((r) => r.json());
  return index;
}

function snippet(text, words) {
  const lower = text.toLowerCase();
  const at = Math.max(0, Math.min(...words.map((w) => lower.indexOf(w)).filter((i) => i >= 0)) - 40);
  return (at > 0 ? "…" : "") + text.slice(at, at + 140).trim() + "…";
}

function search(pages, query) {
  const words = query.toLowerCase().split(/\s+/).filter(Boolean);
  if (!words.length) return [];
  return pages
    .map((p) => {
      const title = p.title.toLowerCase(), text = p.text.toLowerCase();
      if (!words.every((w) => title.includes(w) || text.includes(w))) return null;
      const score = words.reduce((s, w) => s + (title.includes(w) ? 10 : 0) + text.split(w).length - 1, 0);
      return { ...p, score, snippet: snippet(p.text, words) };
    })
    .filter(Boolean)
    .sort((a, b) => b.score - a.score)
    .slice(0, 8);
}

function mount(box) {
  const input = Object.assign(document.createElement("input"), { type: "search", placeholder: "Search", className: "search-input" });
  input.setAttribute("aria-label", "Search the site");
  const results = Object.assign(document.createElement("ul"), { className: "search-results" });
  box.append(input, results);
  input.addEventListener("focus", load, { once: true });
  input.addEventListener("input", async () => {
    const found = search(await load(), input.value);
    results.replaceChildren(...found.map((p) => {
      const li = document.createElement("li"), a = document.createElement("a"), small = document.createElement("small");
      a.href = new URL(p.url, root).href;
      a.textContent = p.title;
      small.textContent = p.snippet;
      a.append(small);
      li.append(a);
      return li;
    }));
    if (input.value && !found.length) results.replaceChildren(Object.assign(document.createElement("li"), { className: "search-none", textContent: "Nothing found" }));
  });
}

document.querySelectorAll("#search").forEach(mount);
