/*
 * Copyright (c) 1999, 2000, 2001 Ariff Abdullah 
 * 	(skywizard@MyBSD.org.my). All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *	$MyBSD$
 *	$FreeBSD$
 *
 */

#include "global.h"
#include <gdk/gdkx.h>

/*static VALUE
progress_set_adjustment(self, adjustment)
     VALUE self, adjustment;
{

    gtk_progress_set_adjustment(GTK_PROGRESS(get_widget(self)),
				GTK_ADJUSTMENT(get_gobject(adjustment)));
    return self;
}

static VALUE
gdkwin_set_static_gravities(self, gravity)
	VALUE self, gravity;
{
	if (gdk_window_set_static_gravities(get_gdkwindow(self), RTEST(gravity)))
		return Qtrue;
	return Qfalse;
}*/

static VALUE
adj_set_upper(self, val)
	VALUE self, val;
{
	GTK_ADJUSTMENT(get_gobject(self))->upper = NUM2DBL(val);
	return self;
}

static VALUE
adj_set_lower(self, val)
	VALUE self, val;
{
	GTK_ADJUSTMENT(get_gobject(self))->lower = NUM2DBL(val);
	return self;
}

static VALUE
adj_set_page_size(self, val)
	VALUE self, val;
{
	GTK_ADJUSTMENT(get_gobject(self))->page_size = NUM2DBL(val);
	return self;
}

static VALUE
adj_set_page_increment(self, val)
	VALUE self, val;
{
	GTK_ADJUSTMENT(get_gobject(self))->page_increment = NUM2DBL(val);
	return self;
}

static VALUE
adj_changed(self)
	VALUE self;
{
	gtk_adjustment_changed(GTK_ADJUSTMENT(get_gobject(self)));
	return self;
}

static VALUE
adj_value_changed(self)
	VALUE self;
{
	gtk_adjustment_value_changed(GTK_ADJUSTMENT(get_Gobject(self)));
	return self;
}

/*static VALUE
scwin_set_vadjustment(self, adj)
	VALUE self, adj;
{
	gtk_scrolled_window_set_vadjustment(
		GTK_SCROLLED_WINDOW(get_widget(self)),
		GTK_ADJUSTMENT(get_gobject(adj)));
	return self;
}

static VALUE
scwin_set_hadjustment(self, adj)
	VALUE self, adj;
{
	gtk_scrolled_window_set_hadjustment(
		GTK_SCROLLED_WINDOW(get_widget(self)),
		GTK_ADJUSTMENT(get_gobject(adj)));
	return self;
}

static VALUE
widget_set_scroll_adjustments(self, hadj, vadj)
	VALUE self, hadj, vadj;
{
	if (gtk_widget_set_scroll_adjustments(get_widget(self),
		GTK_ADJUSTMENT(get_gobject(hadj)),
		GTK_ADJUSTMENT(get_gobject(vadj))))
		return Qtrue;
	return Qfalse;
}*/

static VALUE
gtk_m_update(self)
	VALUE self;
{
	while (gtk_events_pending())
		gtk_main_iteration();
	return Qnil;
}

/*static VALUE
gobj_sig_emit_by_name(self, sig_name)
	VALUE self, sig_name;
{
	gtk_signal_emit_by_name(get_gobject(self), STR2CSTR(sig_name));
	return self;
}*/

/*static VALUE
layout_get_vadjustment(self)
	VALUE self;
{
	GtkAdjustment *vadjustment;
	vadjustment = gtk_layout_get_vadjustment(GTK_LAYOUT(get_widget(self)));
	return make_gobject(gAdjustment, GTK_OBJECT(vadjustment));
}*/

/*static unsigned int darea_signals[2] = {0, 0};*/
static VALUE
darea_initialize(self)
	VALUE self;
{
	GtkWidget *darea;

	darea = gtk_drawing_area_new();
	/* avoiding annoying message from set_scroll_adjustments */
	if (GTK_WIDGET_CLASS (GTK_OBJECT(darea)->klass)->set_scroll_adjustments_signal == 0) {
		GTK_WIDGET_CLASS (GTK_OBJECT(darea)->klass)->set_scroll_adjustments_signal =
			gtk_object_class_user_signal_new(gtk_type_class(GTK_TYPE_DRAWING_AREA),
				"set_scroll_adjustments", GTK_RUN_LAST, gtk_marshal_NONE__POINTER_POINTER,
				GTK_TYPE_NONE, 2, GTK_TYPE_ADJUSTMENT, GTK_TYPE_ADJUSTMENT);
	}
/*	if (darea_signals[0] == 0) {
		darea_signals[0] =
			gtk_object_class_user_signal_new(gtk_type_class(GTK_TYPE_DRAWING_AREA),
				"before_chdir",
				GTK_RUN_LAST, gtk_marshal_NONE__NONE, GTK_TYPE_NONE, 0);
	}
	if (darea_signals[1] == 0) {
		darea_signals[1] =
			gtk_object_class_user_signal_new(gtk_type_class(GTK_TYPE_DRAWING_AREA),
				"after_chdir",
				GTK_RUN_LAST, gtk_marshal_NONE__NONE, GTK_TYPE_NONE, 0);
	}*/
	set_widget(self, darea);
	
	return Qnil;
}

/*static VALUE
darea_send_before_chdir(self)
	VALUE self;
{
	gtk_signal_emit(get_gobject(self), darea_signals[0]);
	return self;
}

static VALUE
darea_send_after_chdir(self)
	VALUE self;
{
	gtk_signal_emit(get_gobject(self), darea_signals[1]);
	return self;
}
*/

static Bool
darea_expose_predicate(display, xev, arg)
	Display *display;
	XEvent *xev;
	XPointer arg;
{
	if (xev->xany.window == ((GdkWindowPrivate *)arg)->xwindow &&
			xev->xany.type == GraphicsExpose)
		return True;
	return False;
}

static VALUE
darea_scroll_flush(self)
	VALUE self;
{
	XEvent xev;
	GdkEventExpose ev;
	Display *display;
	GtkWidget *da;

	da = get_widget(self);
	ev.type = GDK_EXPOSE;
	ev.send_event = TRUE;
	ev.window = da->window;
	display = GDK_WINDOW_XDISPLAY(da->window);

	gdk_flush();
	while (XCheckIfEvent(display, &xev,
			darea_expose_predicate, (XPointer)da->window)) {
		ev.area.x = xev.xexpose.x;
		ev.area.y = xev.xexpose.y;
		ev.area.width = xev.xexpose.width;
		ev.area.height = xev.xexpose.height;
		ev.count = xev.xexpose.count;
		gtk_widget_event(da, (GdkEvent *)&ev);
	}
	return self;
}

void Init_gtk_fix()
{
	/* Gtk::Progress */
	/*rb_define_method(gProgress, "adjustment=", progress_set_adjustment, 1);
	rb_define_method(gProgress, "set_adjustment", progress_set_adjustment, 1);*/
	/* Gdk::Window */
	/*rb_define_method(gdkWindow, "set_static_gravities", gdkwin_set_static_gravities, 1);
	rb_define_method(gdkWindow, "static_gravities=", gdkwin_set_static_gravities, 1);*/
	/* Gtk::Adjustment */
	rb_define_method(gAdjustment, "upper=", adj_set_upper, 1);
	rb_define_method(gAdjustment, "lower=", adj_set_lower, 1);
	rb_define_method(gAdjustment, "page_size=", adj_set_page_size, 1);
	rb_define_method(gAdjustment, "page_increment=", adj_set_page_increment, 1);
	rb_define_method(gAdjustment, "changed", adj_changed, 0);
	rb_define_method(gAdjustment, "value_changed", adj_value_changed, 0);
	/* Gtk::ScrolledWindow */
	/*rb_define_method(gScrolledWin, "set_vadjustment", scwin_set_vadjustment, 1);
	rb_define_method(gScrolledWin, "vadjustment=", scwin_set_vadjustment, 1);
	rb_define_method(gScrolledWin, "set_hadjustment", scwin_set_hadjustment, 1);
	rb_define_method(gScrolledWin, "hadjustment=", scwin_set_hadjustment, 1);*/
	/* Gtk::Widget */
	/*rb_define_method(gWidget, "set_scroll_adjustments", widget_set_scroll_adjustments, 2);*/
	/* Gtk */
	rb_define_module_function(mGtk, "update", gtk_m_update, 0);
	/* Gtk::Object */
	/*rb_define_method(gObject, "signal_emit_by_name", gobj_sig_emit_by_name, 1);*/
	/* Gtk::Layout */
	/*rb_define_method(gLayout, "vadjustment", layout_get_vadjustment, 0);*/
	/* BSD Explorer specific alteration */
	/* Gtk::DrawingArea */
	rb_define_method(gDrawArea, "initialize", darea_initialize, 0);
	/*rb_define_method(gDrawArea, "before_chdir", darea_send_before_chdir, 0);
	rb_define_method(gDrawArea, "after_chdir", darea_send_after_chdir, 0);*/
	rb_define_method(gDrawArea, "scroll_flush", darea_scroll_flush, 0);
}
