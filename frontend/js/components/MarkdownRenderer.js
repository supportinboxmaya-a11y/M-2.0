// Maya 2.0 ULTRA - Markdown Renderer
export class MarkdownRenderer {
  static render(markdown) {
    if (!markdown) return '';
    
    let html = markdown;
    
    // Escape HTML first
    html = this.escapeHtml(html);
    
    // Code blocks (before inline code)
    html = html.replace(/```(\w*)\n([\s\S]*?)```/g, (match, lang, code) => {
      const language = lang ? ` class="language-${lang}"` : '';
      return `<pre><code${language}>${code}</code></pre>`;
    });
    
    // Inline code
    html = html.replace(/`([^`]+)`/g, '<code>$1</code>');
    
    // Bold
    html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
    html = html.replace(/__(.+?)__/g, '<strong>$1</strong>');
    
    // Italic
    html = html.replace(/\*(.+?)\*/g, '<em>$1</em>');
    html = html.replace(/_(.+?)_/g, '<em>$1</em>');
    
    // Strikethrough
    html = html.replace(/~~(.+?)~~/g, '<del>$1</del>');
    
    // Headers
    html = html.replace(/^### (.*$)/gm, '<h3>$1</h3>');
    html = html.replace(/^## (.*$)/gm, '<h2>$1</h2>');
    html = html.replace(/^# (.*$)/gm, '<h1>$1</h1>');
    
    // Links
    html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>');
    
    // Images
    html = html.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '<img src="$2" alt="$1" style="max-width: 100%; height: auto;">');
    
    // Blockquotes
    html = html.replace(/^> (.*$)/gm, '<blockquote>$1</blockquote>');
    
    // Horizontal rule
    html = html.replace(/^---$/gm, '<hr>');
    html = html.replace(/^\*\*\*$/gm, '<hr>');
    
    // Lists
    html = this.renderLists(html);
    
    // Paragraphs
    html = this.renderParagraphs(html);
    
    return html;
  }
  
  static renderLists(html) {
    // Ordered lists
    html = html.replace(/^(\d+)\. (.*$)/gm, '<li>$2</li>');
    html = html.replace(/(<li>.*<\/li>\n?)+/g, (match) => `<ol>${match}</ol>`);
    
    // Unordered lists
    html = html.replace(/^[-*] (.*$)/gm, '<li>$1</li>');
    html = html.replace(/(<li>.*<\/li>\n?)+/g, (match) => {
      if (!match.startsWith('<ol>')) {
        return `<ul>${match}</ul>`;
      }
      return match;
    });
    
    return html;
  }
  
  static renderParagraphs(html) {
    // Split by double newlines
    const blocks = html.split(/\n\n+/);
    const result = blocks.map(block => {
      block = block.trim();
      if (!block) return '';
      
      // Skip if already block element
      if (/^<(h[1-6]|ul|ol|li|blockquote|pre|hr|table|div)/.test(block)) {
        return block;
      }
      
      // Single line breaks to <br>
      block = block.replace(/\n/g, '<br>');
      
      return `<p>${block}</p>`;
    });
    
    return result.join('\n\n');
  }
  
  static escapeHtml(str) {
    return str
      .replace(/&/g, '&')
      .replace(/</g, '<')
      .replace(/>/g, '>')
      .replace(/"/g, '"')
      .replace(/'/g, '&#039;');
  }
  
  static renderToElement(markdown, container) {
    container.innerHTML = this.render(markdown);
    
    // Apply syntax highlighting to code blocks
    container.querySelectorAll('pre code').forEach(block => {
      this.highlightCode(block);
    });
    
    // Make links open in new tab
    container.querySelectorAll('a').forEach(link => {
      link.setAttribute('target', '_blank');
      link.setAttribute('rel', 'noopener noreferrer');
    });
  }
  
  static highlightCode(block) {
    // Simple syntax highlighting
    let code = block.textContent;
    
    // Keywords
    code = code.replace(/\b(const|let|var|function|return|if|else|for|while|class|import|export|from|async|await|try|catch|finally|throw|new|this|super|extends|static|get|set)\b/g, '<span class="kw">$1</span>');
    
    // Types
    code = code.replace(/\b(string|number|boolean|object|array|void|any|unknown|never|Promise|Error|JSON)\b/g, '<span class="type">$1</span>');
    
    // Literals
    code = code.replace(/\b(true|false|null|undefined)\b/g, '<span class="literal">$1</span>');
    
    // Numbers
    code = code.replace(/\b(\d+(\.\d+)?)\b/g, '<span class="number">$1</span>');
    
    // Strings
    code = code.replace(/(["'`])(.*?)\1/g, '<span class="string">$1$2$1</span>');
    
    // Comments
    code = code.replace(/(\/\/.*$)/gm, '<span class="comment">$1</span>');
    code = code.replace(/(\/\*[\s\S]*?\*\/)/g, '<span class="comment">$1</span>');
    
    // Functions
    code = code.replace(/\b([a-zA-Z_$][\w$]*)\s*\(/g, '<span class="func">$1</span>(');
    
    block.innerHTML = code;
  }
}

// Simple syntax highlighting styles (injected via CSS)
const highlightStyles = `
  .code-block pre { margin: 0; padding: var(--space-4); overflow: auto; background: var(--bg-tertiary); border: 1px solid var(--border); border-radius: var(--radius); font-family: var(--font-mono); font-size: var(--text-sm); line-height: 1.7; }
  .code-block code { font-family: inherit; font-size: inherit; color: var(--text-primary); }
  .code-block .kw { color: #c97862; font-weight: 500; }
  .code-block .type { color: #8b6f47; }
  .code-block .literal { color: #a8764a; }
  .code-block .number { color: #4a8a8a; }
  .code-block .string { color: #5a7a5a; }
  .code-block .comment { color: var(--text-tertiary); font-style: italic; }
  .code-block .func { color: #6a8a4a; }
`;

if (!document.getElementById('markdown-highlight-styles')) {
  const style = document.createElement('style');
  style.id = 'markdown-highlight-styles';
  style.textContent = highlightStyles;
  document.head.appendChild(style);
}