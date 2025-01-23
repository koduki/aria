import { ipcRenderer } from 'electron';

document.addEventListener('DOMContentLoaded', () => {
  const messageInput = document.querySelector('textarea');
  const postButton = document.querySelector('.button-area button[title="投稿"]');
  const displayWindow = document.querySelector('.display-window p');

  if (postButton && messageInput && displayWindow) {
    postButton.addEventListener('click', () => {
      const message = messageInput.value;
      ipcRenderer.send('call-chat', message);
      messageInput.value = '';
    });

    ipcRenderer.on('reply-chat', (event, message) => {
      displayWindow.textContent = message;
    });
  }

  const closeButton = document.getElementById('closeButton');
  if (closeButton) {
    closeButton.addEventListener('click', () => {
      window.close();
    });
  }
});
