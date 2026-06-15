const sections = ["heading", "dashboard", "comparison", "features"];
let current = 0;

function updateScrollHint() {
  const hint = document.getElementById("scroll-hint");
  if (hint) hint.classList.toggle("hidden", current >= sections.length - 1);
}

// Copy buttons on code blocks
document.querySelectorAll<HTMLButtonElement>(".copy-button").forEach((btn) => {
  btn.addEventListener("click", async () => {
    const text = btn.dataset.copy ?? "";
    try {
      await navigator.clipboard.writeText(text);
      const label = btn.textContent;
      btn.textContent = "Copied";
      btn.classList.add("copied");
      setTimeout(() => {
        btn.textContent = label;
        btn.classList.remove("copied");
      }, 1200);
    } catch {
      /* clipboard unavailable */
    }
  });
});

function handleKey(key: string) {
  const upKeys = ["ArrowUp", "w", "W", "e", "E"];
  const downKeys = ["ArrowDown", "s", "S", "d", "D", "Enter", " "];

  if (upKeys.includes(key)) {
    if (current > 0) {
      current--;
    } else return;
  } else if (downKeys.includes(key)) {
    if (current < sections.length - 1) {
      current++;
    } else return;
  }

  const sectionId = sections[current];
  if (!sectionId) return;
  const element = document.getElementById(sectionId);
  if (element) {
    element.scrollIntoView({ behavior: "smooth", block: "start" });
  }
  updateScrollHint();
}

updateScrollHint();

const navKeys = [
  "ArrowUp",
  "ArrowDown",
  "w",
  "W",
  "s",
  "S",
  "d",
  "D",
  "e",
  "E",
  " ",
  "Enter",
];

document.addEventListener("keydown", (e) => {
  if (navKeys.includes(e.key)) e.preventDefault();
  handleKey(e.key);
});

let wheelLocked = false;

document.addEventListener(
  "wheel",
  (direction) => {
    direction.preventDefault();
    if (wheelLocked) return;
    wheelLocked = true;
    setTimeout(() => (wheelLocked = false), 800);
    if (direction.deltaY > 0) {
      handleKey("ArrowDown");
    } else if (direction.deltaY < 0) {
      handleKey("ArrowUp");
    }
  },
  { passive: false },
);

let touchStartY = 0;
let touchLocked = false;

document.addEventListener(
  "touchstart",
  (e) => {
    const touch = e.touches[0];
    if (touch) touchStartY = touch.clientY;
  },
  { passive: true },
);

document.addEventListener(
  "touchend",
  (e) => {
    if (touchLocked) return;
    const touch = e.changedTouches[0];
    if (!touch) return;
    const deltaY = touchStartY - touch.clientY;
    if (Math.abs(deltaY) < 30) return;
    touchLocked = true;
    setTimeout(() => (touchLocked = false), 800);
    if (deltaY > 0) {
      handleKey("ArrowDown");
    } else {
      handleKey("ArrowUp");
    }
  },
  { passive: true },
);
