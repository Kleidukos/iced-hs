use canvas::{Cache, Frame, Geometry, Program};
use iced::widget::{canvas, Canvas};
use iced::{mouse, Length, Rectangle, Renderer, Theme};

use crate::{free_haskell_fun_ptr, ElementPtr, IcedMessage};

mod fill;
mod frame;
mod gradient;
mod path;
mod path_builder;
mod stroke;
mod style;
mod text;

type SelfPtr = *mut Canvas<&'static CanvasState, IcedMessage>;

#[repr(transparent)]
struct Draw {
    inner: extern "C" fn(frame: *mut Frame),
}

// Can't call Haskell function from a finalizer, need
// to find some other way to free this callback
// impl Drop for Draw {
//     fn drop(&mut self) {
//         println!("Calling drop in Draw");
//         unsafe { free_haskell_fun_ptr(self.inner as usize) }
//     }
// }

pub struct CanvasState {
    cache: Cache,
    draw_hs: Option<Draw>,
}

impl<Message> Program<Message> for CanvasState {
    type State = ();

    fn draw(
        &self,
        _state: &Self::State,
        renderer: &Renderer,
        _theme: &Theme,
        bounds: Rectangle,
        _cursor: mouse::Cursor,
    ) -> Vec<Geometry> {
        let Some(draw) = &self.draw_hs else {
            return vec![];
        };
        let geometry = self.cache.draw(renderer, bounds.size(), |frame| {
            (draw.inner)(frame);
        });
        vec![geometry]
    }
}

#[no_mangle]
extern "C" fn canvas_state_new() -> *mut CanvasState {
    let state = CanvasState {
        cache: Cache::default(),
        draw_hs: None,
    };
    Box::into_raw(Box::new(state))
}

#[no_mangle]
extern "C" fn canvas_set_draw(state: &mut CanvasState, draw: Draw) {
    if let Some(old) = state.draw_hs.replace(draw) {
        unsafe { free_haskell_fun_ptr(old.inner as usize) }
    }
}

#[no_mangle]
extern "C" fn canvas_remove_draw(state: &mut CanvasState) {
    state.draw_hs = None;
}

#[no_mangle]
extern "C" fn canvas_clear_cache(state: &mut CanvasState) {
    state.cache.clear();
}

#[no_mangle]
extern "C" fn canvas_state_free(pointer: *mut CanvasState) {
    let _ = unsafe { Box::from_raw(pointer) };
}

#[no_mangle]
extern "C" fn canvas_new(state: &'static CanvasState) -> SelfPtr {
    let canvas = canvas(state);
    Box::into_raw(Box::new(canvas))
}

#[no_mangle]
extern "C" fn canvas_width(self_ptr: SelfPtr, width: *mut Length) -> SelfPtr {
    let canvas = unsafe { Box::from_raw(self_ptr) };
    let width = unsafe { *Box::from_raw(width) };
    Box::into_raw(Box::new(canvas.width(width)))
}

#[no_mangle]
extern "C" fn canvas_height(self_ptr: SelfPtr, height: *mut Length) -> SelfPtr {
    let canvas = unsafe { Box::from_raw(self_ptr) };
    let height = unsafe { *Box::from_raw(height) };
    Box::into_raw(Box::new(canvas.height(height)))
}

#[no_mangle]
extern "C" fn canvas_into_element(self_ptr: SelfPtr) -> ElementPtr {
    let canvas = unsafe { *Box::from_raw(self_ptr) };
    Box::into_raw(Box::new(canvas.into()))
}
