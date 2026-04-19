function header_click_all_checkboxes(source) {
  var cls = source.getAttribute('data-cat');
  if (!cls) {
    return;
  }
  var boxes = document.querySelectorAll('input.jr_cb.' + cls);
  var on = source.checked;
  for (var i = 0; i < boxes.length; i++) {
    boxes[i].checked = on;
  }
}

function banpanel_select_all_except_other() {
  document.querySelectorAll('input.jr_cb').forEach(function (cb) {
    var col = cb.closest('.banrole-column');
    if (col && col.classList.contains('ban-cat-other')) {
      cb.checked = false;
    } else {
      cb.checked = true;
    }
  });
}

/** Снять галочки со всех ролей вне категории Other (для снятия джоббанов — затем «Снять джоббаны»). */
function banpanel_unban_all_except_other() {
  document.querySelectorAll('input.jr_cb').forEach(function (cb) {
    var col = cb.closest('.banrole-column');
    if (col && col.classList.contains('ban-cat-other')) {
      return;
    }
    cb.checked = false;
  });
}
