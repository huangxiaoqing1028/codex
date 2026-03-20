const form = document.getElementById('resumeForm');
const previewBtn = document.getElementById('previewBtn');
const previewBox = document.getElementById('previewBox');

const splitLines = (value = '') =>
  value
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean);

const parseForm = () => {
  const fd = new FormData(form);
  return {
    name: fd.get('name')?.toString().trim() || '',
    title: fd.get('title')?.toString().trim() || '',
    phone: fd.get('phone')?.toString().trim() || '',
    email: fd.get('email')?.toString().trim() || '',
    city: fd.get('city')?.toString().trim() || '',
    website: fd.get('website')?.toString().trim() || '',
    summary: fd.get('summary')?.toString().trim() || '',
    education: splitLines(fd.get('education')?.toString() || ''),
    experience: (fd.get('experience')?.toString() || '')
      .split('\n\n')
      .map((item) => item.trim())
      .filter(Boolean),
    skills: (fd.get('skills')?.toString() || '')
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean),
    projects: splitLines(fd.get('projects')?.toString() || ''),
  };
};

previewBtn.addEventListener('click', () => {
  const data = parseForm();
  previewBox.innerHTML = `<h3>预览</h3><pre>${JSON.stringify(data, null, 2)}</pre>`;
});

const addSectionTitle = (doc, title, y) => {
  doc.setFillColor(66, 84, 255);
  doc.roundedRect(14, y - 5, 182, 8, 2, 2, 'F');
  doc.setFontSize(11);
  doc.setTextColor(255, 255, 255);
  doc.text(title, 18, y);
  return y + 8;
};

const renderWrapped = (doc, text, x, y, maxWidth, lineHeight = 6) => {
  if (!text) return y;
  const lines = doc.splitTextToSize(text, maxWidth);
  lines.forEach((line) => {
    if (y > 280) {
      doc.addPage();
      y = 20;
    }
    doc.text(line, x, y);
    y += lineHeight;
  });
  return y;
};

form.addEventListener('submit', (e) => {
  e.preventDefault();
  const data = parseForm();
  const { jsPDF } = window.jspdf;
  const doc = new jsPDF({ unit: 'mm', format: 'a4' });

  doc.setFillColor(17, 32, 76);
  doc.rect(0, 0, 70, 297, 'F');

  doc.setTextColor(255, 255, 255);
  doc.setFontSize(20);
  doc.text(data.name || '未命名候选人', 8, 20);
  doc.setFontSize(10);
  doc.text(data.title || '目标岗位', 8, 28);

  doc.setFontSize(9);
  const sidebarInfo = [
    `📱 ${data.phone || '-'}`,
    `✉️ ${data.email || '-'}`,
    `📍 ${data.city || '-'}`,
    `🔗 ${data.website || '-'}`,
  ];
  let sideY = 42;
  sidebarInfo.forEach((line) => {
    doc.text(doc.splitTextToSize(line, 52), 8, sideY);
    sideY += 10;
  });

  if (data.skills.length) {
    doc.setFontSize(11);
    doc.text('核心技能', 8, sideY + 4);
    sideY += 12;
    doc.setFontSize(9);
    data.skills.forEach((skill) => {
      if (sideY > 280) {
        doc.addPage();
        sideY = 20;
      }
      doc.text(`• ${skill}`, 8, sideY);
      sideY += 6;
    });
  }

  let y = 18;
  const rightX = 78;
  const rightW = 118;
  doc.setTextColor(27, 34, 56);

  y = addSectionTitle(doc, '个人简介', y);
  doc.setFontSize(10);
  y = renderWrapped(doc, data.summary || '暂无', rightX, y, rightW);

  y += 4;
  y = addSectionTitle(doc, '工作经历', y);
  doc.setFontSize(10);
  if (!data.experience.length) {
    y = renderWrapped(doc, '暂无', rightX, y, rightW);
  } else {
    data.experience.forEach((item) => {
      y = renderWrapped(doc, `• ${item.replace(/\n/g, '\n  ')}`, rightX, y, rightW);
      y += 2;
    });
  }

  y += 2;
  y = addSectionTitle(doc, '教育背景', y);
  doc.setFontSize(10);
  if (!data.education.length) {
    y = renderWrapped(doc, '暂无', rightX, y, rightW);
  } else {
    data.education.forEach((line) => {
      y = renderWrapped(doc, `• ${line}`, rightX, y, rightW);
    });
  }

  y += 2;
  y = addSectionTitle(doc, '项目亮点', y);
  if (!data.projects.length) {
    renderWrapped(doc, '暂无', rightX, y, rightW);
  } else {
    data.projects.forEach((line) => {
      y = renderWrapped(doc, `• ${line}`, rightX, y, rightW);
    });
  }

  doc.save(`${data.name || 'resume'}_简历.pdf`);
});
