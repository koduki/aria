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

ipcMain.on('request-window-info', (event) => {
  console.log("Hello")
  const mainWindow = BrowserWindow.getFocusedWindow();
  if (!mainWindow) {
    return;
  }
  const { x, y, width, height } = mainWindow.getBounds();
  const newWindowX = x - 100;
  const newWindowY = y + 150;

  let textWindow: BrowserWindow | null = new BrowserWindow({
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

  textWindow.loadFile(path.join(__dirname, '../public/text-window.html'));

  setTimeout(() => {
    if (textWindow) {
      textWindow.close();
    }
  }, 10*1000);

  textWindow.on('closed', () => {
    textWindow = null;
  });
});
