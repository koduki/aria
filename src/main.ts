import { app, BrowserWindow, ipcMain } from 'electron';
import * as path from 'path';

function createWindow() {
  const mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    transparent: true,
    frame: false,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    }
  });

  ipcMain.on('move-window', (event, arg) => {
    const win = BrowserWindow.getFocusedWindow();
    if (win) {
      const { x, y, startWindowX, startWindowY } = arg;
      win.setPosition(startWindowX + x, startWindowY + y);
    }
  });

  mainWindow.setMenuBarVisibility(false);
  mainWindow.loadFile(path.join(__dirname, '..', 'public', 'index.html'));
  mainWindow.webContents.openDevTools();
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', function () {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

let chatWindow: BrowserWindow | null = null;

ipcMain.on('open-chat', (event) => {
  console.log("Hello");
  const mainWindow = BrowserWindow.getFocusedWindow();
  if (!mainWindow) {
    return;
  }
  const { x, y, width, height } = mainWindow.getBounds();
  const newWindowX = x - 100;
  const newWindowY = y + 150;

  chatWindow = new BrowserWindow({
    x: newWindowX,
    y: newWindowY,
    width: 400,
    height: 150,
    parent: mainWindow,
    frame: false,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
  });

  chatWindow.loadFile(path.join(__dirname, '../public/chat-window.html'));
  // chatWindow.webContents.openDevTools();

  setTimeout(() => {
    if (chatWindow) {
      chatWindow.close();
    }
  }, 10 * 1000);

  chatWindow.on('closed', () => {
    chatWindow = null;
  });
});

ipcMain.on('call-chat', (event, message) => {
  if (chatWindow && chatWindow.webContents) {
    let msg = message + "::::";
    chatWindow.webContents.send('reply-chat', msg);
  }
});
