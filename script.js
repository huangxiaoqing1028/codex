const output = document.getElementById('output');
const history = document.getElementById('history');
const keys = document.querySelector('.keys');

const state = {
  current: '0',
  previous: null,
  operator: null,
  overwrite: false,
};

function formatNumber(value) {
  if (value === '错误') return value;
  const num = Number(value);
  if (!Number.isFinite(num)) return '错误';
  return num.toLocaleString('zh-CN', { maximumFractionDigits: 10 });
}

function updateDisplay() {
  output.textContent = formatNumber(state.current);
  if (state.previous !== null && state.operator) {
    history.textContent = `${formatNumber(state.previous)} ${symbol(state.operator)}`;
  } else {
    history.textContent = '';
  }
}

function symbol(op) {
  return { '/': '÷', '*': '×', '-': '−', '+': '+' }[op] ?? op;
}

function inputNumber(num) {
  if (state.overwrite) {
    state.current = num;
    state.overwrite = false;
    return;
  }
  state.current = state.current === '0' ? num : `${state.current}${num}`;
}

function inputDecimal() {
  if (state.overwrite) {
    state.current = '0.';
    state.overwrite = false;
    return;
  }
  if (!state.current.includes('.')) state.current += '.';
}

function clearAll() {
  state.current = '0';
  state.previous = null;
  state.operator = null;
  state.overwrite = false;
}

function deleteOne() {
  if (state.overwrite) return;
  state.current = state.current.length <= 1 ? '0' : state.current.slice(0, -1);
}

function compute() {
  if (state.previous === null || !state.operator) return;
  const a = Number(state.previous);
  const b = Number(state.current);
  let result;

  switch (state.operator) {
    case '+':
      result = a + b;
      break;
    case '-':
      result = a - b;
      break;
    case '*':
      result = a * b;
      break;
    case '/':
      result = b === 0 ? NaN : a / b;
      break;
    default:
      return;
  }

  state.current = Number.isFinite(result) ? String(result) : '错误';
  state.previous = null;
  state.operator = null;
  state.overwrite = true;
}

function chooseOperator(op) {
  if (state.current === '错误') clearAll();
  if (state.operator && !state.overwrite) compute();
  state.previous = state.current;
  state.operator = op;
  state.overwrite = true;
}

keys.addEventListener('click', (event) => {
  const button = event.target.closest('button');
  if (!button) return;

  const { action, value } = button.dataset;

  switch (action) {
    case 'number':
      inputNumber(value);
      break;
    case 'decimal':
      inputDecimal();
      break;
    case 'operator':
      chooseOperator(value);
      break;
    case 'equals':
      compute();
      break;
    case 'clear':
      clearAll();
      break;
    case 'delete':
      deleteOne();
      break;
    default:
      return;
  }

  updateDisplay();
});

window.addEventListener('keydown', (event) => {
  const { key } = event;

  if (/^[0-9]$/.test(key)) inputNumber(key);
  else if (key === '.') inputDecimal();
  else if (['+', '-', '*', '/'].includes(key)) chooseOperator(key);
  else if (key === 'Enter' || key === '=') compute();
  else if (key === 'Backspace') deleteOne();
  else if (key.toLowerCase() === 'c') clearAll();
  else return;

  updateDisplay();
});

updateDisplay();
