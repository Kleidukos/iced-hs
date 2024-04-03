use std::ffi::{c_char, c_int};

use iced::theme;
use iced::widget::{checkbox, Checkbox};

use crate::{HaskellMessage, IcedMessage};

use super::{c_string_to_rust, ElementPtr};

type CheckboxPtr = *mut Checkbox<'static, IcedMessage>;

type ToggleCallback = unsafe extern "C" fn(input: c_int) -> *const u8;

#[no_mangle]
pub extern "C" fn new_checkbox(input: *mut c_char, value: c_int) -> CheckboxPtr {
    let label = c_string_to_rust(input);
    let is_checked = match value {
        0 => false,
        1 => true,
        _ => panic!("Non boolean value passed to checkbox"),
    };
    Box::into_raw(Box::new(checkbox(label, is_checked)))
}

#[no_mangle]
pub extern "C" fn checkbox_on_toggle(
    pointer: CheckboxPtr,
    on_toggle: ToggleCallback,
) -> CheckboxPtr {
    let mut checkbox = unsafe { *Box::from_raw(pointer) };
    checkbox = checkbox.on_toggle(move |new_value| {
        let message_ptr = unsafe { on_toggle(new_value.into()) };
        IcedMessage::Ptr(HaskellMessage { ptr: message_ptr })
    });
    Box::into_raw(Box::new(checkbox))
}

#[no_mangle]
pub extern "C" fn checkbox_style(
    pointer: CheckboxPtr,
    style_ptr: *mut theme::Checkbox,
) -> CheckboxPtr {
    let checkbox = unsafe { *Box::from_raw(pointer) };
    let style = unsafe { *Box::from_raw(style_ptr) };
    Box::into_raw(Box::new(checkbox.style(style)))
}

#[no_mangle]
pub extern "C" fn checkbox_into_element(pointer: CheckboxPtr) -> ElementPtr {
    let checkbox = unsafe { *Box::from_raw(pointer) };
    Box::into_raw(Box::new(checkbox.into()))
}

#[no_mangle]
pub extern "C" fn checkbox_primary() -> *mut theme::Checkbox {
    Box::into_raw(Box::new(theme::Checkbox::Primary))
}

#[no_mangle]
pub extern "C" fn checkbox_secondary() -> *mut theme::Checkbox {
    Box::into_raw(Box::new(theme::Checkbox::Secondary))
}

#[no_mangle]
pub extern "C" fn checkbox_success() -> *mut theme::Checkbox {
    Box::into_raw(Box::new(theme::Checkbox::Success))
}

#[no_mangle]
pub extern "C" fn checkbox_danger() -> *mut theme::Checkbox {
    Box::into_raw(Box::new(theme::Checkbox::Danger))
}

// #[no_mangle]
// pub extern "C" fn checkbox_custom() -> *mut theme::Checkbox {
//     Box::into_raw(Box::new(theme::Checkbox::Custom))
// }
