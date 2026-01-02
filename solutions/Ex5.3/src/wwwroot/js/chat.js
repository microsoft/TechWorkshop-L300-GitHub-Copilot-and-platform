// Chat functionality for AI assistant
(function () {
    'use strict';

    const messageInput = document.getElementById('messageInput');
    const sendButton = document.getElementById('sendButton');
    const clearButton = document.getElementById('clearButton');
    const chatConversation = document.getElementById('chatConversation');
    const errorMessage = document.getElementById('errorMessage');

    let conversationHistory = [];
    let isLoading = false;

    // Initialize
    function init() {
        sendButton.addEventListener('click', sendMessage);
        clearButton.addEventListener('click', clearConversation);
        messageInput.addEventListener('keypress', function (e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                sendMessage();
            }
        });

        // Auto-focus on input
        messageInput.focus();
    }

    // Send message to server
    async function sendMessage() {
        const message = messageInput.value.trim();

        if (!message) {
            return;
        }

        if (message.length > 500) {
            showError('Message is too long. Maximum 500 characters allowed.');
            return;
        }

        if (isLoading) {
            return;
        }

        // Hide error if visible
        hideError();

        // Add user message to conversation
        addMessageToConversation('user', message);
        conversationHistory.push({ role: 'user', content: message });

        // Clear input
        messageInput.value = '';

        // Show loading state
        setLoading(true);
        const loadingId = showLoadingMessage();

        try {
            const response = await fetch('/Chat/SendMessage', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    message: message,
                    history: conversationHistory.slice(-10) // Send last 10 messages for context
                })
            });

            // Remove loading message
            removeLoadingMessage(loadingId);

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Failed to get response from AI');
            }

            const data = await response.json();

            // Add AI response to conversation
            addMessageToConversation('assistant', data.response);
            conversationHistory.push({ role: 'assistant', content: data.response });

        } catch (error) {
            removeLoadingMessage(loadingId);
            console.error('Error sending message:', error);
            showError(error.message || 'An error occurred. Please try again.');
        } finally {
            setLoading(false);
            messageInput.focus();
        }
    }

    // Add message to conversation display
    function addMessageToConversation(role, content) {
        // Clear welcome message if this is the first message
        if (conversationHistory.length === 0) {
            chatConversation.innerHTML = '';
        }

        const messageDiv = document.createElement('div');
        messageDiv.className = `mb-3 ${role === 'user' ? 'text-end' : 'text-start'}`;

        const messageBubble = document.createElement('div');
        messageBubble.className = `d-inline-block p-2 rounded ${role === 'user'
            ? 'bg-primary text-white'
            : 'bg-white border'}`;
        messageBubble.style.maxWidth = '80%';

        const roleLabel = document.createElement('small');
        roleLabel.className = `d-block fw-bold ${role === 'user' ? 'text-white-50' : 'text-muted'}`;
        roleLabel.textContent = role === 'user' ? 'You' : 'AI Assistant';

        const messageText = document.createElement('div');
        messageText.textContent = content;
        messageText.style.whiteSpace = 'pre-wrap';

        messageBubble.appendChild(roleLabel);
        messageBubble.appendChild(messageText);
        messageDiv.appendChild(messageBubble);
        chatConversation.appendChild(messageDiv);

        // Scroll to bottom
        chatConversation.scrollTop = chatConversation.scrollHeight;
    }

    // Show loading indicator
    function showLoadingMessage() {
        const loadingDiv = document.createElement('div');
        loadingDiv.id = 'loadingMessage';
        loadingDiv.className = 'mb-3 text-start';

        const loadingBubble = document.createElement('div');
        loadingBubble.className = 'd-inline-block p-2 rounded bg-white border';

        const spinner = document.createElement('div');
        spinner.className = 'spinner-border spinner-border-sm text-primary me-2';
        spinner.setAttribute('role', 'status');

        const text = document.createElement('span');
        text.textContent = 'AI is thinking...';

        loadingBubble.appendChild(spinner);
        loadingBubble.appendChild(text);
        loadingDiv.appendChild(loadingBubble);
        chatConversation.appendChild(loadingDiv);

        // Scroll to bottom
        chatConversation.scrollTop = chatConversation.scrollHeight;

        return 'loadingMessage';
    }

    // Remove loading indicator
    function removeLoadingMessage(id) {
        const loadingMsg = document.getElementById(id);
        if (loadingMsg) {
            loadingMsg.remove();
        }
    }

    // Clear conversation
    function clearConversation() {
        if (conversationHistory.length === 0) {
            return;
        }

        if (confirm('Are you sure you want to clear the conversation?')) {
            conversationHistory = [];
            chatConversation.innerHTML = `
                <div class="text-muted text-center mt-5">
                    <i class="bi bi-chat-text" style="font-size: 3rem;"></i>
                    <p class="mt-2">Start a conversation! Ask me anything about our products.</p>
                </div>
            `;
            hideError();
            messageInput.focus();
        }
    }

    // Show error message
    function showError(message) {
        errorMessage.textContent = message;
        errorMessage.classList.remove('d-none');
    }

    // Hide error message
    function hideError() {
        errorMessage.classList.add('d-none');
    }

    // Set loading state
    function setLoading(loading) {
        isLoading = loading;
        sendButton.disabled = loading;
        messageInput.disabled = loading;

        if (loading) {
            sendButton.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Sending...';
        } else {
            sendButton.innerHTML = '<i class="bi bi-send-fill me-1"></i>Send';
        }
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
