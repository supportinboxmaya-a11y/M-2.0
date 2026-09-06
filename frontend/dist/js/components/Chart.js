// Maya 2.0 ULTRA - Chart Component (Simple SVG Charts)
export class Chart {
  constructor(container, options = {}) {
    this.container = container;
    this.options = {
      type: 'bar', // bar, line, area, pie, donut
      data: [],
      labels: [],
      colors: ['var(--accent)', 'var(--success)', 'var(--warning)', 'var(--info)', 'var(--error)'],
      height: 280,
      width: '100%',
      padding: { top: 20, right: 20, bottom: 40, left: 50 },
      showGrid: true,
      showLegend: true,
      showTooltips: true,
      animate: true,
      ...options
    };
    this.svg = null;
    this.tooltip = null;
    this.render();
  }
  
  render() {
    const { width, height } = this.options;
    
    this.container.innerHTML = `
      <div class="chart-container" style="width: ${width}; height: ${height}px; position: relative;">
        <svg class="chart-svg" width="100%" height="100%" viewBox="0 0 ${this.getWidth()} ${this.getHeight()}" preserveAspectRatio="none"></svg>
        ${this.options.showTooltips ? '<div class="chart-tooltip" style="display: none; position: absolute; pointer-events: none; z-index: 100;"></div>' : ''}
      </div>
      ${this.options.showLegend ? '<div class="chart-legend" style="display: flex; flex-wrap: wrap; gap: var(--space-3); margin-top: var(--space-3);"></div>' : ''}
    `;
    
    this.svg = this.container.querySelector('.chart-svg');
    this.tooltip = this.container.querySelector('.chart-tooltip');
    this.legendContainer = this.container.querySelector('.chart-legend');
    
    this.drawChart();
    this.renderLegend();
    this.bindEvents();
  }
  
  getWidth() {
    return 800; // Base width for viewBox
  }
  
  getHeight() {
    return 400; // Base height for viewBox
  }
  
  getChartArea() {
    const { padding } = this.options;
    const width = this.getWidth();
    const height = this.getHeight();
    
    return {
      x: padding.left,
      y: padding.top,
      width: width - padding.left - padding.right,
      height: height - padding.top - padding.bottom
    };
  }
  
  drawChart() {
    switch (this.options.type) {
      case 'bar':
        this.drawBarChart();
        break;
      case 'line':
        this.drawLineChart();
        break;
      case 'area':
        this.drawAreaChart();
        break;
      case 'pie':
        this.drawPieChart();
        break;
      case 'donut':
        this.drawDonutChart();
        break;
    }
  }
  
  drawBarChart() {
    const { data, labels } = this.options;
    if (!data.length) return;
    
    const area = this.getChartArea();
    const maxValue = Math.max(...data.flat());
    const barWidth = area.width / (data[0].length * 1.5);
    const groupWidth = area.width / data[0].length;
    
    // Y axis
    this.drawYAxis(maxValue);
    this.drawXAxis(labels);
    
    // Bars
    data.forEach((series, seriesIndex) => {
      const color = this.options.colors[seriesIndex % this.options.colors.length];
      
      series.forEach((value, index) => {
        const x = area.x + index * groupWidth + seriesIndex * barWidth + (groupWidth - data.length * barWidth) / 2;
        const barHeight = (value / maxValue) * area.height;
        const y = area.y + area.height - barHeight;
        
        const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
        rect.setAttribute('x', x);
        rect.setAttribute('y', this.options.animate ? area.y + area.height : y);
        rect.setAttribute('width', barWidth);
        rect.setAttribute('height', this.options.animate ? 0 : barHeight);
        rect.setAttribute('fill', color);
        rect.setAttribute('rx', 2);
        rect.setAttribute('data-value', value);
        rect.setAttribute('data-label', labels[index] || index);
        rect.setAttribute('data-series', seriesIndex);
        rect.style.transition = this.options.animate ? 'height 0.5s ease-out, y 0.5s ease-out' : 'none';
        
        if (this.options.animate) {
          requestAnimationFrame(() => {
            rect.setAttribute('y', y);
            rect.setAttribute('height', barHeight);
          });
        }
        
        this.svg.appendChild(rect);
      });
    });
  }
  
  drawLineChart() {
    const { data, labels } = this.options;
    if (!data.length) return;
    
    const area = this.getChartArea();
    const maxValue = Math.max(...data.flat());
    
    this.drawYAxis(maxValue);
    this.drawXAxis(labels);
    
    data.forEach((series, seriesIndex) => {
      const color = this.options.colors[seriesIndex % this.options.colors.length];
      
      const points = series.map((value, index) => {
        const x = area.x + (index / (series.length - 1)) * area.width;
        const y = area.y + area.height - (value / maxValue) * area.height;
        return `${x},${y}`;
      }).join(' ');
      
      const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      path.setAttribute('d', `M${points}`);
      path.setAttribute('stroke', color);
      path.setAttribute('stroke-width', 2);
      path.setAttribute('fill', 'none');
      path.setAttribute('stroke-linecap', 'round');
      path.setAttribute('stroke-linejoin', 'round');
      path.style.transition = this.options.animate ? 'stroke-dashoffset 0.5s ease-out' : 'none';
      
      if (this.options.animate) {
        const length = path.getTotalLength();
        path.style.strokeDasharray = length;
        path.style.strokeDashoffset = length;
        requestAnimationFrame(() => {
          path.style.strokeDashoffset = 0;
        });
      }
      
      this.svg.appendChild(path);
      
      // Points
      series.forEach((value, index) => {
        const x = area.x + (index / (series.length - 1)) * area.width;
        const y = area.y + area.height - (value / maxValue) * area.height;
        
        const circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
        circle.setAttribute('cx', x);
        circle.setAttribute('cy', y);
        circle.setAttribute('r', 4);
        circle.setAttribute('fill', color);
        circle.setAttribute('stroke', 'var(--bg-card)');
        circle.setAttribute('stroke-width', 2);
        circle.setAttribute('data-value', value);
        circle.setAttribute('data-label', labels[index] || index);
        circle.setAttribute('data-series', seriesIndex);
        
        this.svg.appendChild(circle);
      });
    });
  }
  
  drawAreaChart() {
    // Similar to line chart but with fill
    this.drawLineChart();
    
    const { data } = this.options;
    const area = this.getChartArea();
    const maxValue = Math.max(...data.flat());
    
    data.forEach((series, seriesIndex) => {
      const color = this.options.colors[seriesIndex % this.options.colors.length];
      
      const points = series.map((value, index) => {
        const x = area.x + (index / (series.length - 1)) * area.width;
        const y = area.y + area.height - (value / maxValue) * area.height;
        return `${x},${y}`;
      }).join(' ');
      
      const areaPath = `M${area.x},${area.y + area.height} L${points} L${area.x + area.width},${area.y + area.height} Z`;
      
      const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      path.setAttribute('d', areaPath);
      path.setAttribute('fill', color);
      path.setAttribute('fill-opacity', 0.2);
      path.style.transition = this.options.animate ? 'opacity 0.5s ease-out' : 'none';
      
      if (this.options.animate) {
        path.style.opacity = 0;
        requestAnimationFrame(() => {
          path.style.opacity = 0.2;
        });
      }
      
      this.svg.insertBefore(path, this.svg.firstChild);
    });
  }
  
  drawPieChart() {
    const { data, labels } = this.options;
    if (!data.length) return;
    
    const area = this.getChartArea();
    const centerX = area.x + area.width / 2;
    const centerY = area.y + area.height / 2;
    const radius = Math.min(area.width, area.height) / 2 * 0.8;
    
    const total = data.reduce((a, b) => a + b, 0);
    let currentAngle = -Math.PI / 2;
    
    data.forEach((value, index) => {
      const sliceAngle = (value / total) * 2 * Math.PI;
      const color = this.options.colors[index % this.options.colors.length];
      
      const x1 = centerX + radius * Math.cos(currentAngle);
      const y1 = centerY + radius * Math.sin(currentAngle);
      const x2 = centerX + radius * Math.cos(currentAngle + sliceAngle);
      const y2 = centerY + radius * Math.sin(currentAngle + sliceAngle);
      
      const largeArc = sliceAngle > Math.PI ? 1 : 0;
      
      const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      path.setAttribute('d', `M${centerX},${centerY} L${x1},${y1} A${radius},${radius} 0 ${largeArc},1 ${x2},${y2} Z`);
      path.setAttribute('fill', color);
      path.setAttribute('stroke', 'var(--bg-card)');
      path.setAttribute('stroke-width', 2);
      path.setAttribute('data-value', value);
      path.setAttribute('data-label', labels[index] || index);
      path.style.transition = this.options.animate ? 'transform 0.5s ease-out' : 'none';
      path.style.transformOrigin = `${centerX}px ${centerY}px`;
      
      if (this.options.animate) {
        path.style.transform = `rotate(${currentAngle * 180 / Math.PI - 90}deg) scale(0)`;
        requestAnimationFrame(() => {
          path.style.transform = `rotate(${currentAngle * 180 / Math.PI - 90}deg) scale(1)`;
        });
      }
      
      this.svg.appendChild(path);
      currentAngle += sliceAngle;
    });
  }
  
  drawDonutChart() {
    this.drawPieChart();
    
    // Add center circle for donut effect
    const area = this.getChartArea();
    const centerX = area.x + area.width / 2;
    const centerY = area.y + area.height / 2;
    const radius = Math.min(area.width, area.height) / 2 * 0.8;
    const innerRadius = radius * 0.6;
    
    const circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
    circle.setAttribute('cx', centerX);
    circle.setAttribute('cy', centerY);
    circle.setAttribute('r', innerRadius);
    circle.setAttribute('fill', 'var(--bg-card)');
    circle.setAttribute('stroke', 'var(--bg-card)');
    circle.setAttribute('stroke-width', 2);
    
    this.svg.appendChild(circle);
    
    // Total in center
    const total = this.options.data.reduce((a, b) => a + b, 0);
    const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
    text.setAttribute('x', centerX);
    text.setAttribute('y', centerY + 6);
    text.setAttribute('text-anchor', 'middle');
    text.setAttribute('dominant-baseline', 'middle');
    text.setAttribute('font-size', '24');
    text.setAttribute('font-weight', '600');
    text.setAttribute('fill', 'var(--text-primary)');
    text.textContent = total.toLocaleString();
    
    this.svg.appendChild(text);
  }
  
  drawYAxis(maxValue) {
    const area = this.getChartArea();
    const ticks = 5;
    
    for (let i = 0; i <= ticks; i++) {
      const value = (maxValue / ticks) * (ticks - i);
      const y = area.y + (i / ticks) * area.height;
      
      // Grid line
      if (this.options.showGrid) {
        const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
        line.setAttribute('x1', area.x);
        line.setAttribute('y1', y);
        line.setAttribute('x2', area.x + area.width);
        line.setAttribute('y2', y);
        line.setAttribute('stroke', 'var(--border)');
        line.setAttribute('stroke-width', 1);
        this.svg.appendChild(line);
      }
      
      // Label
      const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
      text.setAttribute('x', area.x - 10);
      text.setAttribute('y', y + 4);
      text.setAttribute('text-anchor', 'end');
      text.setAttribute('font-size', '12');
      text.setAttribute('fill', 'var(--text-tertiary)');
      text.textContent = this.formatNumber(value);
      this.svg.appendChild(text);
    }
    
    // Axis line
    const axis = document.createElementNS('http://www.w3.org/2000/svg', 'line');
    axis.setAttribute('x1', area.x);
    axis.setAttribute('y1', area.y);
    axis.setAttribute('x2', area.x);
    axis.setAttribute('y2', area.y + area.height);
    axis.setAttribute('stroke', 'var(--border-strong)');
    axis.setAttribute('stroke-width', 1);
    this.svg.appendChild(axis);
  }
  
  drawXAxis(labels) {
    const area = this.getChartArea();
    
    if (!labels.length) return;
    
    labels.forEach((label, index) => {
      const x = area.x + (index / (labels.length - 1)) * area.width;
      const y = area.y + area.height + 20;
      
      const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
      text.setAttribute('x', x);
      text.setAttribute('y', y);
      text.setAttribute('text-anchor', 'middle');
      text.setAttribute('font-size', '12');
      text.setAttribute('fill', 'var(--text-tertiary)');
      text.textContent = label;
      this.svg.appendChild(text);
    });
    
    // Axis line
    const axis = document.createElementNS('http://www.w3.org/2000/svg', 'line');
    axis.setAttribute('x1', area.x);
    axis.setAttribute('y1', area.y + area.height);
    axis.setAttribute('x2', area.x + area.width);
    axis.setAttribute('y2', area.y + area.height);
    axis.setAttribute('stroke', 'var(--border-strong)');
    axis.setAttribute('stroke-width', 1);
    this.svg.appendChild(axis);
  }
  
  renderLegend() {
    if (!this.legendContainer) return;
    
    const { data, labels } = this.options;
    
    if (this.options.type === 'pie' || this.options.type === 'donut') {
      // Single series - show labels as legend
      labels.forEach((label, index) => {
        const value = data[index];
        const color = this.options.colors[index % this.options.colors.length];
        
        const item = document.createElement('div');
        item.className = 'chart-legend-item';
        item.style.cssText = 'display: flex; align-items: center; gap: var(--space-2); font-size: var(--text-sm);';
        item.innerHTML = `
          <span style="width: 12px; height: 12px; border-radius: 2px; background: ${color};"></span>
          <span>${label}: ${value.toLocaleString()}</span>
        `;
        this.legendContainer.appendChild(item);
      });
    } else {
      // Multi-series - show series names
      data.forEach((series, seriesIndex) => {
        const color = this.options.colors[seriesIndex % this.options.colors.length];
        const label = `Series ${seriesIndex + 1}`;
        
        const item = document.createElement('div');
        item.className = 'chart-legend-item';
        item.style.cssText = 'display: flex; align-items: center; gap: var(--space-2); font-size: var(--text-sm);';
        item.innerHTML = `
          <span style="width: 12px; height: 12px; border-radius: 2px; background: ${color};"></span>
          <span>${label}</span>
        `;
        this.legendContainer.appendChild(item);
      });
    }
  }
  
  bindEvents() {
    if (!this.options.showTooltips || !this.tooltip) return;
    
    this.svg.addEventListener('mousemove', (e) => {
      const rect = this.svg.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      
      // Find nearest data point
      const elements = this.svg.querySelectorAll('[data-value]');
      let nearest = null;
      let minDist = Infinity;
      
      elements.forEach(el => {
        const elRect = el.getBoundingClientRect();
        const elX = (elRect.left + elRect.right) / 2 - rect.left;
        const elY = (elRect.top + elRect.bottom) / 2 - rect.top;
        const dist = Math.hypot(x - elX, y - elY);
        
        if (dist < minDist && dist < 30) {
          minDist = dist;
          nearest = el;
        }
      });
      
      if (nearest) {
        this.showTooltip(nearest, x, y);
      } else {
        this.hideTooltip();
      }
    });
    
    this.svg.addEventListener('mouseleave', () => this.hideTooltip());
  }
  
  showTooltip(element, x, y) {
    const value = element.dataset.value;
    const label = element.dataset.label;
    const series = element.dataset.series;
    
    this.tooltip.style.display = 'block';
    this.tooltip.style.left = `${x + 10}px`;
    this.tooltip.style.top = `${y - 40}px`;
    this.tooltip.innerHTML = `
      <div style="background: var(--bg-card); border: 1px solid var(--border); border-radius: var(--radius); padding: var(--space-2) var(--space-3); box-shadow: var(--shadow-lg); font-size: var(--text-sm);">
        ${label ? `<div style="font-weight: 600; color: var(--text-primary);">${label}</div>` : ''}
        <div style="color: var(--text-secondary);">Value: ${Number(value).toLocaleString()}</div>
        ${series !== undefined ? `<div style="color: var(--text-tertiary);">Series: ${Number(series) + 1}</div>` : ''}
      </div>
    `;
  }
  
  hideTooltip() {
    if (this.tooltip) {
      this.tooltip.style.display = 'none';
    }
  }
  
  formatNumber(num) {
    if (num >= 1e9) return (num / 1e9).toFixed(1) + 'B';
    if (num >= 1e6) return (num / 1e6).toFixed(1) + 'M';
    if (num >= 1e3) return (num / 1e3).toFixed(1) + 'K';
    return num.toLocaleString();
  }
  
  update(data, labels) {
    this.options.data = data;
    this.options.labels = labels || this.options.labels;
    this.svg.innerHTML = '';
    this.legendContainer.innerHTML = '';
    this.drawChart();
    this.renderLegend();
  }
  
  destroy() {
    if (this.container) {
      this.container.innerHTML = '';
    }
  }
}