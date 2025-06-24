const canvas = document.getElementById('matrixCanvas');
const ctx = canvas.getContext('2d');

let width, height, cols, rows;
const fontSize = 14;
let matrix = [];
let coverageMap = [];
let coveragePercent = 0;
let animationId = null;

function randomChar() {
  return Math.random() > 0.5 ? '1' : '0';
}

function resizeCanvas() {
  const dpr = window.devicePixelRatio || 1;
  width = window.innerWidth;
  height = window.innerHeight;
  canvas.width = width * dpr;
  canvas.height = height * dpr;
  canvas.style.width = width + 'px';
  canvas.style.height = height + 'px';
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.scale(dpr, dpr);
  ctx.imageSmoothingEnabled = false;
  ctx.textRendering = 'geometricPrecision';
  ctx.font = `${fontSize}px 'Fira Code', monospace`;

  const newCols = Math.ceil(width / fontSize);
  const newRows = Math.ceil(height / fontSize);

  for (let x = matrix.length; x < newCols; x++) {
    const col = [], covCol = [];
    for (let y = 0; y < newRows; y++) {
      col.push({
        char: randomChar(),
        brightness: Math.random(),
        delay: Math.floor(Math.random() * 1000),
        flickerSpeed: 20 + Math.floor(Math.random() * 50),
        active: false,
      });
      covCol.push(false);
    }
    matrix.push(col);
    coverageMap.push(covCol);
  }

  for (let x = 0; x < newCols; x++) {
    if (!matrix[x]) matrix[x] = [];
    if (!coverageMap[x]) coverageMap[x] = [];
    for (let y = matrix[x].length; y < newRows; y++) {
      matrix[x].push({
        char: randomChar(),
        brightness: Math.random(),
        delay: Math.floor(Math.random() * 1000),
        flickerSpeed: 20 + Math.floor(Math.random() * 80),
        active: false,
      });
      coverageMap[x].push(false);
    }
    matrix[x].length = newRows;
    coverageMap[x].length = newRows;
  }

  matrix.length = newCols;
  coverageMap.length = newCols;
  cols = newCols;
  rows = newRows;
}

function seedRandomCells(count) {
  for (let i = 0; i < count; i++) {
    const x = Math.floor(Math.random() * cols);
    const y = Math.floor(Math.random() * rows);
    matrix[x][y].active = true;
    coverageMap[x][y] = true;
  }
}

function spreadAndFlicker() {
  ctx.fillStyle = 'rgba(0, 0, 0, 0.2)';
  ctx.fillRect(0, 0, width, height);
  ctx.font = fontSize + "px 'Fira Code', monospace";
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';

  for (let x = 0; x < cols; x++) {
    for (let y = 0; y < rows; y++) {
      const cell = matrix[x][y];
      if (cell.active) {
        if (cell.delay-- <= 0) {
          cell.char = randomChar();
          cell.brightness = Math.random() * 0.9 + 0.1;
          cell.delay = cell.flickerSpeed;
        }
        ctx.fillStyle = `rgba(0,255,0,${cell.brightness})`;
        ctx.fillText(cell.char, x * fontSize, y * fontSize);

        [[1, 0], [-1, 0], [0, 1], [0, -1]].forEach(([dx, dy]) => {
          const nx = x + dx;
          const ny = y + dy;
          if (nx >= 0 && ny >= 0 && nx < cols && ny < rows && !matrix[nx][ny].active) {
            if (Math.random() > 0.95) {
              matrix[nx][ny].active = true;
              coverageMap[nx][ny] = true;
            }
          }
        });
      }
    }
  }

  const total = cols * rows;
  const filled = coverageMap.flat().filter(Boolean).length;
  coveragePercent = filled / total;

  if (coveragePercent >= 0.98 && !window.preloadFinished) {
    window.preloadFinished = true;
    setTimeout(showTerminal, 1000);
  }

  animationId = requestAnimationFrame(spreadAndFlicker);
}

function showTerminal() {
  const preloadEl = document.getElementById('preloader');
  const terminalContent = document.getElementById('terminalContent');
  const terminalBox = document.querySelector('.terminal');

  preloadEl.style.opacity = '0';
  terminalContent.classList.remove('opacity-0');
  terminalContent.classList.add('opacity-100');
  terminalBox.classList.remove('translucent');

  setTimeout(() => {
    preloadEl.style.display = 'none';
    startTyping();
    makeTerminalDraggable(); // ✅ Activate dragging after loading
  }, 3000);

  setTimeout(() => {
    document.body.classList.add('matrix-dimmed');
    terminalBox.classList.add('terminal-glow');
  }, 2900);
}

const terminalLines = [
  "$ whoami",
  "Aryan Kaushal",
  "$ echo \"Welcome to my terminal portfolio.\"",
  "Welcome to my terminal portfolio."
];
let termIndex = 0;

function startTyping() {
  const container = document.getElementById("terminalContent");
  const cursor = document.createElement("span");
  cursor.className = "typing-cursor";

  function typeNextLine() {
    if (termIndex >= terminalLines.length) return;

    const line = document.createElement("span");
    line.className = "line";
    container.appendChild(line);
    container.appendChild(cursor);
    let text = terminalLines[termIndex];
    let charIndex = 0;

    function typeChar() {
      if (charIndex < text.length) {
        line.textContent += text[charIndex++];
        setTimeout(typeChar, 50);
      } else {
        termIndex++;
        setTimeout(typeNextLine, 400);
      }
    }

    typeChar();
  }

  typeNextLine();
}

function typeLoadingText() {
  const line1 = document.getElementById("preloadLine1");
  const line2 = document.getElementById("preloadLine2");

  const text1 = "Terminal is loading...";
  const text2 = "Please wait...";

  let i = 0, j = 0;

  function typeFirstLine() {
    if (i < text1.length) {
      line1.textContent += text1.charAt(i++);
      setTimeout(typeFirstLine, 80);
    } else {
      setTimeout(typeSecondLine, 400);
    }
  }

  function typeSecondLine() {
    if (j < text2.length) {
      line2.textContent += text2.charAt(j++);
      setTimeout(typeSecondLine, 80);
    }
  }

  typeFirstLine();
}

function makeTerminalDraggable() {
  const terminal = document.querySelector('.terminal');
  const header = terminal.querySelector('.terminal-header');

  let isDragging = false;
  let offsetX = 0;
  let offsetY = 0;

  header.addEventListener('mousedown', (e) => {
    if (terminal.classList.contains('translucent')) return;

    const rect = terminal.getBoundingClientRect();

    terminal.style.transform = 'none';
    terminal.style.position = 'absolute';
    terminal.style.left = `${rect.left}px`;
    terminal.style.top = `${rect.top}px`;

    offsetX = e.clientX - rect.left;
    offsetY = e.clientY - rect.top;
    isDragging = true;

    // Disable text selection while dragging
    document.body.style.userSelect = 'none';
  });

  document.addEventListener('mousemove', (e) => {
    if (!isDragging) return;

    const x = e.clientX - offsetX;
    const y = e.clientY - offsetY;

    // Clamp to viewport: prevent header from going above or outside left
    const minTop = 0;
    const minLeft = 0;
    const maxLeft = window.innerWidth - terminal.offsetWidth;
    const maxTop = window.innerHeight - 40; // optional bottom limit (e.g. 40px from bottom)

    const clampedX = Math.min(Math.max(x, minLeft), maxLeft);
    const clampedY = Math.max(y, minTop); // we allow downward drag

    terminal.style.left = `${clampedX}px`;
    terminal.style.top = `${clampedY}px`;
  });

  document.addEventListener('mouseup', () => {
    isDragging = false;
    document.body.style.userSelect = '';
  });
}



function init() {
  resizeCanvas();
  typeLoadingText();
  setTimeout(() => {
    seedRandomCells(10);
    spreadAndFlicker();
    initBanner();
    animateBannerWave();
  }, 5000);
}

init();
window.addEventListener("resize", resizeCanvas);
