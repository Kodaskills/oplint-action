const btn = document.getElementById('copy-btn');
const snippet = document.getElementById('code-snippet');

btn.addEventListener('click', () => {
  const text = snippet.innerText;
  navigator.clipboard.writeText(text).then(() => {
    btn.classList.add('copied');
    setTimeout(() => btn.classList.remove('copied'), 2000);
  });
});
