use std::ffi::{c_char, c_uchar};

use iced::widget::markdown::{self, Item};

use super::{read_c_string, ElementPtr};

type StatePtr = *mut State;

type OnUrlClickFFI = extern "C" fn(url: *mut c_char) -> *const u8;

struct State {
    items: Vec<Item>,
}

#[no_mangle]
extern "C" fn markdown_state_new(input: *mut c_char) -> StatePtr {
    let string = read_c_string(input);
    let items = markdown::parse(&string).collect();
    let state = State { items };
    Box::into_raw(Box::new(state))
}

#[no_mangle]
extern "C" fn markdown_state_free(state_ptr: StatePtr) {
    let _ = unsafe { Box::from_raw(state_ptr) };
}

#[no_mangle]
extern "C" fn markdown_view(
    state_ptr: StatePtr,
    theme_raw: c_uchar,
    on_url_click_ffi: OnUrlClickFFI,
) -> ElementPtr {
    let state = unsafe { Box::from_raw(state_ptr) };
    let theme = crate::theme::theme_from_raw(theme_raw);
    let on_url_click = super::wrap_callback_with_string(on_url_click_ffi);
    let view = markdown::view(
        &Box::leak(state).items,
        markdown::Settings::default(),
        markdown::Style::from_palette(theme.palette()),
    )
    .map(move |url| on_url_click(url.as_str().to_owned()));
    Box::into_raw(Box::new(view))
}
