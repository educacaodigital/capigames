// Variáveis de estado
let currentSize = 4;
let solutionBoard = [];
let playerBoard = [];

// Elementos do DOM
const menuScreen = document.getElementById('menu-screen');
const gameScreen = document.getElementById('game-screen');
const boardElement = document.getElementById('sudoku-board');
const messageBox = document.getElementById('message-box');

// --- Funções de Controle de Tela ---

function startGame(size) {
    currentSize = size;
    
    // Ocultar menu, mostrar jogo
    menuScreen.classList.add('d-none');
    gameScreen.classList.remove('d-none');
    gameScreen.classList.add('d-flex');
    messageBox.textContent = '';

    // Atualiza o texto lá em cima dependendo do nível escolhido
    const levelText = document.getElementById('level-indicator');
    if (levelText) { // Verifica se o elemento existe para não dar erro
        if (size === 4) {
            levelText.textContent = "Nível: Fácil (4x4)";
            levelText.className = "fw-bold text-primary"; // Azul
        } else {
            levelText.textContent = "Nível: Difícil (6x6)";
            levelText.className = "fw-bold text-danger"; // Vermelho
        }
    }

    // Ajustar CSS Grid dinamicamente
    boardElement.style.gridTemplateColumns = `repeat(${size}, 1fr)`;

    // Gerar lógica do jogo
    generateGameLevel(size);
    renderBoard();
}

function backToMenu() {
    gameScreen.classList.add('d-none');
    gameScreen.classList.remove('d-flex');
    menuScreen.classList.remove('d-none');
}

// --- Lógica do Sudoku (Geração e Validação) ---

function generateGameLevel(size) {
    // 1. Criar um tabuleiro vazio
    solutionBoard = Array.from({ length: size }, () => Array(size).fill(0));

    // 2. Preencher o tabuleiro com uma solução válida (Backtracking)
    solveSudoku(solutionBoard, size);

    // 3. Copiar para o tabuleiro do jogador e remover alguns números
    // No modo 4x4, removemos cerca de 6-8 números. No 6x6, cerca de 15-18.
    playerBoard = JSON.parse(JSON.stringify(solutionBoard)); // Deep copy
    
    const attempts = size === 4 ? 8 : 20; // Dificuldade
    for (let i = 0; i < attempts; i++) {
        let row = Math.floor(Math.random() * size);
        let col = Math.floor(Math.random() * size);
        playerBoard[row][col] = 0; // 0 representa vazio
    }
}

// Algoritmo simples de Backtracking para gerar solução
function solveSudoku(board, n) {
    for (let row = 0; row < n; row++) {
        for (let col = 0; col < n; col++) {
            if (board[row][col] === 0) {
                // Tentar números de 1 a n
                let nums = Array.from({ length: n }, (_, i) => i + 1);
                nums.sort(() => Math.random() - 0.5); // Embaralhar para aleatoriedade

                for (let num of nums) {
                    if (isValid(board, row, col, num, n)) {
                        board[row][col] = num;
                        if (solveSudoku(board, n)) return true;
                        board[row][col] = 0;
                    }
                }
                return false;
            }
        }
    }
    return true;
}

// Verifica se o número pode ser colocado na posição
function isValid(board, row, col, num, n) {
    // Checar linha e coluna
    for (let x = 0; x < n; x++) {
        if (board[row][x] === num || board[x][col] === num) return false;
    }

    // Checar região (Bloco)
    // 4x4: blocos de 2x2
    // 6x6: blocos de 2 linhas x 3 colunas
    let boxRowHeight = 2;
    let boxColWidth = n === 6 ? 3 : 2;

    let startRow = row - row % boxRowHeight;
    let startCol = col - col % boxColWidth;

    for (let i = 0; i < boxRowHeight; i++) {
        for (let j = 0; j < boxColWidth; j++) {
            if (board[i + startRow][j + startCol] === num) return false;
        }
    }

    return true;
}

// --- Renderização e Interação ---

function renderBoard() {
    boardElement.innerHTML = ''; // Limpar
    let boxColWidth = currentSize === 6 ? 3 : 2;

    for (let r = 0; r < currentSize; r++) {
        for (let c = 0; c < currentSize; c++) {
            const cellValue = playerBoard[r][c];
            const cell = document.createElement('div');
            
            cell.classList.add('cell');
            
            // Adicionar bordas mais grossas para separar regiões visualmente
            if ((c + 1) % boxColWidth === 0 && c !== currentSize - 1) {
                cell.style.marginRight = "4px"; 
            }
            if ((r + 1) % 2 === 0 && r !== currentSize - 1) {
                cell.style.marginBottom = "4px";
            }

            if (cellValue !== 0) {
                cell.textContent = cellValue;
                cell.classList.add('fixed'); // Números iniciais não mudam
            } else {
                // Célula jogável
                cell.onclick = () => handleCellClick(cell, r, c);
            }

            // Guardar coordenadas para validação visual
            cell.dataset.row = r;
            cell.dataset.col = c;

            boardElement.appendChild(cell);
        }
    }
}

function handleCellClick(element, r, c) {
    // Lógica de incremento: 0 -> 1 -> 2 ... -> Max -> 0
    let val = playerBoard[r][c];
    val++;
    
    if (val > currentSize) {
        val = 0; // Volta para vazio (apagar)
    }

    playerBoard[r][c] = val;
    element.textContent = val === 0 ? '' : val;
    
    // Remove estilos de validação anteriores se houver
    element.classList.remove('correct', 'wrong');
}

function checkWin() {
    let isCorrect = true;
    const cells = document.querySelectorAll('.cell:not(.fixed)');

    // Verificar apenas as células preenchidas pelo jogador
    cells.forEach(cell => {
        const r = parseInt(cell.dataset.row);
        const c = parseInt(cell.dataset.col);
        const val = playerBoard[r][c];

        if (val === solutionBoard[r][c]) {
            cell.classList.add('correct');
            cell.classList.remove('wrong');
        } else {
            cell.classList.add('wrong');
            cell.classList.remove('correct');
            isCorrect = false;
        }
    });

    // Verificar se todas as células estão preenchidas e corretas
    let allFilled = true;
    for(let r=0; r<currentSize; r++){
        for(let c=0; c<currentSize; c++){
            if(playerBoard[r][c] === 0) allFilled = false;
        }
    }

    if (isCorrect && allFilled) {
        messageBox.innerHTML = "<span class='text-success'>Parabéns! Você venceu! 🎉</span>";
    } else if (!allFilled) {
        messageBox.innerHTML = "<span class='text-warning'>O tabuleiro ainda não está completo.</span>";
    } else {
        messageBox.innerHTML = "<span class='text-danger'>Ops! Algo está errado. Verifique as células vermelhas.</span>";
    }
}