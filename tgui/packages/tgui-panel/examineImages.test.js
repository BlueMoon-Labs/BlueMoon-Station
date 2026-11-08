import { captureExamineImages } from './examineImages';

beforeAll(() => captureExamineImages());

afterEach(() => {
  document.dispatchEvent(new Event('scroll'));
  document.body.innerHTML = '';
});

test.each(['examine_portrait', 'examine_thumb'])('%s collapses until the pointer leaves its enlarged area', cssClass => {
  document.body.innerHTML = `<div class="examine_block"><img class="${cssClass}"></div>`;
  const image = document.querySelector('img');
  image.getBoundingClientRect = () => ({ left: 10, top: 10, right: 210, bottom: 210 });
  image.dispatchEvent(new MouseEvent('click', { bubbles: true, button: 0 }));
  expect(image.classList.contains('examine_image_collapsed')).toBe(true);

  // После сворачивания курсор может оказаться за пределами исходного размера.
  document.dispatchEvent(new MouseEvent('mousemove', { clientX: 180, clientY: 180 }));
  expect(image.classList.contains('examine_image_collapsed')).toBe(true);
  document.dispatchEvent(new MouseEvent('mousemove', { clientX: 220, clientY: 180 }));
  expect(image.classList.contains('examine_image_collapsed')).toBe(false);
});

test('right click and placeholder images do not collapse', () => {
  document.body.innerHTML = '<div class="examine_block">'
    + '<img class="examine_thumb"><img class="examine_placeholder"></div>';
  const [thumb, placeholder] = document.querySelectorAll('img');
  thumb.dispatchEvent(new MouseEvent('click', { bubbles: true, button: 2 }));
  placeholder.dispatchEvent(new MouseEvent('click', { bubbles: true, button: 0 }));
  expect(document.querySelector('.examine_image_collapsed')).toBeNull();
});
