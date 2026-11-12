// ЛКМ сворачивает увеличенный хедшот до следующего наведения.
export const captureExamineImages = () => {
  let collapsedImage;
  let hoverBounds;

  const reset = () => {
    collapsedImage?.classList.remove('examine_image_collapsed');
    collapsedImage = null;
    hoverBounds = null;
  };

  document.addEventListener('click', event => {
    const target = event.target;
    if (event.button !== 0 || !(target instanceof Element)
      || !target.matches('.examine_block img.examine_portrait, .examine_block img.examine_thumb')) {
      return;
    }
    if (target === collapsedImage) {
      return;
    }
    reset();
    // Сохраняем область увеличенной картинки: сворачивание под курсором
    // не должно сразу запускать повторное увеличение.
    hoverBounds = target.getBoundingClientRect();
    collapsedImage = target;
    target.classList.add('examine_image_collapsed');
  });

  document.addEventListener('mousemove', event => {
    if (!collapsedImage) {
      return;
    }
    if (!collapsedImage.isConnected
      || event.clientX < hoverBounds.left || event.clientX > hoverBounds.right
      || event.clientY < hoverBounds.top || event.clientY > hoverBounds.bottom) {
      reset();
    }
  });

  document.addEventListener('scroll', reset, true);
};
