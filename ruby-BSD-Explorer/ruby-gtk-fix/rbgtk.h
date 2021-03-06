/* -*- c-file-style: "ruby" -*- */
/************************************************

  rbgtk.h -

  $Author: mutoh $
  $Date: 2003/12/24 16:46:10 $

  Copyright (C) 1998-2000 Yukihiro Matsumoto,
                          Daisuke Kanda,
                          Hiroshi Igarashi
************************************************/

#ifndef _RBGTK_H
#define _RBGTK_H

#include "ruby.h"
#include "rubysig.h"
#include <gtk/gtk.h>
#include <glib.h>

#if defined HAVE_GDK_GDKX_H
# include <gdk/gdkx.h> /* for GDK_ROOT_WINDOW() */
#elif defined G_OS_WIN32
# if !defined HWND_DESKTOP
#  define HWND_DESKTOP 0
# endif
# define GDK_ROOT_WINDOW() ((guint32) HWND_DESKTOP)
#endif

#if HAVE_RB_BLOCK_PROC
#define G_BLOCK_PROC rb_block_proc
#else
#define G_BLOCK_PROC rb_f_lambda
#endif

#include <signal.h>

#define CSTR2OBJ(s) (s ? rb_str_new2(s) : Qnil)
#define RUBY_GTK_OBJ_KEY "__ruby_gtk_object__"

#ifdef StringValuePtr
#undef STR2CSTR
#define STR2CSTR(v) StringValuePtr(v)
#endif

extern VALUE glist2ary(GList* list);
extern GList* ary2glist(VALUE ary);
extern GSList* ary2gslist(VALUE ary);
extern VALUE gslist2ary(GSList *list);

extern ID id_gtkdata;
extern ID id_relatives;
extern ID id_relative_callbacks;
extern ID id_call;

struct _rbgtk_class_info {
    VALUE klass;
    GtkType gtype;
    void (*mark)(GtkObject *);
    void (*free)(GtkObject *);
};

typedef struct _rbgtk_class_info rbgtk_class_info;

extern void rbgtk_register_class(rbgtk_class_info *cinfo);
extern rbgtk_class_info *rbgtk_lookup_class(VALUE klass);
extern rbgtk_class_info *rbgtk_lookup_class_by_gtype(GtkType gtype);

extern VALUE warn_handler;
extern VALUE mesg_handler;
extern VALUE print_handler;

extern VALUE mRC;
extern VALUE mGtk;
extern VALUE mGtkDrag;
extern VALUE gError;
extern VALUE gObject;
extern VALUE gWidget;
extern VALUE gContainer;
extern VALUE gBin;
extern VALUE gAccelLabel;
extern VALUE gAlignment;
extern VALUE gMisc;
extern VALUE gArrow;
extern VALUE gFrame;
extern VALUE gAspectFrame;
extern VALUE gData;
extern VALUE gAdjustment;
extern VALUE gBox;
extern VALUE gButton;
extern VALUE gTButton;
extern VALUE gCButton;
extern VALUE gRButton;
extern VALUE gBBox;
extern VALUE gCalendar;
extern VALUE gCList;
extern VALUE gCTree;
extern VALUE gCTreeNode;
extern VALUE gWindow;
extern VALUE gDialog;
extern VALUE gFileSel;
extern VALUE gVBox;
extern VALUE gColorSel;
extern VALUE gColorSelDialog;
extern VALUE gCombo;
extern VALUE gImage;
extern VALUE gDrawArea;
extern VALUE gEditable;
extern VALUE gEntry;
extern VALUE gSButton;
extern VALUE gEventBox;
extern VALUE gFixed;
extern VALUE gFontSelection;
extern VALUE gFontSelectionDialog;
extern VALUE gGamma;
extern VALUE gCurve;
extern VALUE gHBBox;
extern VALUE gVBBox;
extern VALUE gHBox;
extern VALUE gPaned;
extern VALUE gHPaned;
extern VALUE gVPaned;
extern VALUE gRuler;
extern VALUE gHRuler;
extern VALUE gVRuler;
extern VALUE gRange;
extern VALUE gScale;
extern VALUE gHScale;
extern VALUE gVScale;
extern VALUE gScrollbar;
extern VALUE gHScrollbar;
extern VALUE gVScrollbar;
extern VALUE gSeparator;
extern VALUE gHSeparator;
extern VALUE gVSeparator;
extern VALUE gInputDialog;
extern VALUE gLabel;
extern VALUE gLayout;
extern VALUE gList;
extern VALUE gItem;
extern VALUE gListItem;
extern VALUE gMenuShell;
extern VALUE gMenu;
extern VALUE gMenuBar;
extern VALUE gMenuItem;
extern VALUE gCMenuItem;
extern VALUE gRMenuItem;
extern VALUE gTMenuItem;
extern VALUE gNotebook;
extern VALUE gNotePage;
extern VALUE gOptionMenu;
extern VALUE gPixmap;
extern VALUE gPreview;
extern VALUE gProgress;
extern VALUE gProgressBar;
extern VALUE gScrolledWin;
extern VALUE gStatusBar;
extern VALUE gTable;
extern VALUE gText;
extern VALUE gTipsQuery;
extern VALUE gToolbar;
extern VALUE gTooltips;
extern VALUE gTree;
extern VALUE gTreeItem;
extern VALUE gViewport;
extern VALUE gHandleBox;
extern VALUE gPlug;
extern VALUE gSocket;
extern VALUE gPacker;

extern VALUE gAccelGroup;
extern VALUE gStyle;
extern VALUE gRcStyle;
extern VALUE gPreviewInfo;
extern VALUE gAllocation;
extern VALUE gRequisition;
extern VALUE gItemFactory;
extern VALUE gIFConst;
extern VALUE gSelectionData;

extern VALUE mGdk;
extern VALUE mGdkKeyval;
extern VALUE mGdkSelection;
extern VALUE gdkError;
extern VALUE gdkFont;
extern VALUE gdkColor;
extern VALUE gdkColormap;
extern VALUE gdkDrawable;
extern VALUE gdkPixmap;
extern VALUE gdkBitmap;
extern VALUE gdkWindow;
extern VALUE gdkImage;
extern VALUE gdkVisual;
extern VALUE gdkGC;
extern VALUE gdkPoint;
extern VALUE gdkRectangle;
extern VALUE gdkRegion;
extern VALUE gdkGCValues;
extern VALUE gdkSegment;
extern VALUE gdkWindowAttr;
extern VALUE gdkCursor;
extern VALUE gdkCursorConst;
extern VALUE gdkAtom;
extern VALUE gdkColorContext;
extern VALUE gdkEvent;

extern VALUE gdkEventType;
extern VALUE gdkEventAny;
extern VALUE gdkEventExpose;
extern VALUE gdkEventNoExpose;
extern VALUE gdkEventVisibility;
extern VALUE gdkEventMotion;
extern VALUE gdkEventButton;
extern VALUE gdkEventKey;
extern VALUE gdkEventCrossing;
extern VALUE gdkEventFocus;
extern VALUE gdkEventConfigure;
extern VALUE gdkEventProperty;
extern VALUE gdkEventSelection;
extern VALUE gdkEventDND;
extern VALUE gdkEventProximity;
/*
extern VALUE gdkEventDragBegin;
extern VALUE gdkEventDragRequest;
extern VALUE gdkEventDropEnter;
extern VALUE gdkEventDropLeave;
extern VALUE gdkEventDropDataAvailable;
*/
extern VALUE gdkEventClient;
extern VALUE gdkEventOther;
extern VALUE gdkDragContext;
extern VALUE gdkDragContextConst;

extern VALUE mGdkIM;
extern VALUE gdkIC;
extern VALUE gdkICAttr;

extern VALUE mGdkRgb;

/*
 * for gtk
 */
extern VALUE get_value_from_gobject(GtkObject* obj);
extern GtkObject* get_gobject(VALUE obj);
extern void set_gobject(VALUE obj, GtkObject *gtkobj);
extern GtkWidget* get_widget(VALUE obj);
extern VALUE make_gobject(VALUE klass, GtkObject* gtkobj);
extern VALUE make_widget(VALUE klass, GtkWidget* widget);

extern VALUE get_gtk_type(GtkObject* gtkobj);
extern VALUE make_gobject_auto_type(GtkObject* gtkobj);

extern VALUE make_gstyle(GtkStyle* style);
extern GtkStyle* get_gstyle(VALUE style);

#ifndef NT
extern VALUE make_grcstyle(GtkRcStyle* style);
#endif
extern GtkRcStyle* get_grcstyle(VALUE style);

extern VALUE make_ctree_node(GtkCTreeNode* node);
extern VALUE make_notepage(GtkNotebookPage* page);

/* extern void exec_callback(GtkWidget *widget, VALUE proc); */
extern void exec_callback(GtkWidget *widget, gpointer proc);

extern VALUE make_gtkaccelgrp(GtkAccelGroup* accel);
extern GtkAccelGroup *get_gtkaccelgrp(VALUE value);

extern VALUE make_gtkselectiondata(GtkSelectionData* selectiondata);
extern GtkSelectionData *get_gtkselectiondata(VALUE value);

extern VALUE make_gtkprevinfo(GtkPreviewInfo* info);
extern GtkPreviewInfo* get_gtkprevinfo(VALUE value);

extern void set_widget(VALUE obj, GtkWidget *widget);
extern void add_relative(VALUE obj, VALUE relative);
extern void add_relative_removable(VALUE obj, VALUE relative,
                                   ID obj_ivar_id, VALUE hash_key);
extern void remove_relative(VALUE obj, ID obj_ivar_id, VALUE hash_key);

/*
 * for gdk
 */
extern VALUE make_tobj(gpointer obj, VALUE klass, int size);
extern gpointer get_tobj(VALUE obj, VALUE klass);

#define make_gdkcolor(c) make_tobj(c, gdkColor, sizeof(GdkColor))
#define get_gdkcolor(c) ((GdkColor*)get_tobj(c, gdkColor))

#define make_gdksegment(c) make_tobj(c, gdkSegment, sizeof(GdkSegment))
#define get_gdksegment(c) ((GdkSegment*)get_tobj(c, gdkSegment))

#define make_gdkwinattr(c) make_tobj(c, gdkWindowAttr, sizeof(GdkWindowAttr))
#define get_gdkwinattr(c) ((GdkWindowAttr*)get_tobj(c, gdkWindowAttr))

#define make_gdkwinattr(c) make_tobj(c, gdkWindowAttr, sizeof(GdkWindowAttr))
#define get_gdkwinattr(c) ((GdkWindowAttr*)get_tobj(c, gdkWindowAttr))

#define make_gallocation(c) make_tobj(c, gAllocation, sizeof(GtkAllocation))
#define get_gallocation(c) ((GtkAllocation*)get_tobj(c, gAllocation))

#define make_grequisition(c) make_tobj(c, gRequisition, sizeof(GtkRequisition))
#define get_grequisition(c) ((GtkRequisition*)get_tobj(c, gRequisition))

#define make_gdkpoint(r) make_tobj(r, gdkPoint, sizeof(GdkPoint))
#define get_gdkpoint(r) ((GdkPoint*)get_tobj(r, gdkPoint))

#define make_gdkrectangle(r) make_tobj(r, gdkRectangle, sizeof(GdkRectangle))
#define get_gdkrectangle(r) ((GdkRectangle*)get_tobj(r, gdkRectangle))

extern VALUE make_gdkregion(GdkRegion* region);
extern GdkRegion* get_gdkregion(VALUE region);

extern VALUE make_gdkfont(GdkFont* font);
extern GdkFont* get_gdkfont(VALUE font);

extern VALUE make_gdkcmap(GdkColormap* cmap);
extern GdkColormap* get_gdkcmap(VALUE cmap);

extern VALUE make_gdkcursor(GdkCursor* cursor);
extern GdkCursor* get_gdkcursor(VALUE cursor);

extern VALUE make_gdkvisual(GdkVisual* visual);
extern GdkVisual* get_gdkvisual(VALUE visual);

typedef void(*gdkdrawfunc)();

extern VALUE make_gdkdraw(VALUE klass, GdkDrawable* draw,
						  void (*ref)(), void (*unref)());

extern VALUE make_gdkwindow(GdkWindow* window);
extern VALUE make_gdkpixmap(GdkPixmap* pixmap);
extern VALUE make_gdkbitmap(GdkBitmap* bitmap);

extern VALUE new_gdkwindow(GdkWindow* window);
extern VALUE new_gdkpixmap(GdkPixmap* pixmap);
extern VALUE new_gdkbitmap(GdkBitmap* bitmap);

extern GdkWindow* get_gdkdraw(VALUE draw, VALUE klass, const char* kname);
#define get_gdkdrawable(w) get_gdkdraw((w),gdkDrawable,"GdkDrawable")
#define get_gdkwindow(w) get_gdkdraw((w),gdkWindow,"GdkWindow")
#define get_gdkpixmap(w) get_gdkdraw((w),gdkPixmap,"GdkPixmap")
#define get_gdkbitmap(w) get_gdkdraw((w),gdkBitmap,"GdkBitmap")

extern VALUE make_gdkimage(GdkImage* image);
extern GdkImage* get_gdkimage(VALUE image);

extern VALUE make_gdkevent(GdkEvent* event);
extern GdkEvent* get_gdkevent(VALUE event);

extern VALUE make_gdkgc(GdkGC* gc);
extern GdkGC* get_gdkgc(VALUE gc);

extern VALUE make_gdkic(GdkIC *ic);
extern VALUE make_gdkicattr(GdkICAttr *attr);
#define get_gdkic(a) ((GdkIC*)get_tobj(a, gdkIC))
#define get_gdkicattr(a) ((GdkICAttr*)get_tobj(a, gdkICAttr))

extern VALUE rbgdk_geometry_make(GdkGeometry *geo);
extern GdkGeometry *rbgdk_geometry_get(VALUE geo);

extern VALUE make_gdkdragcontext(GdkDragContext* context);
extern VALUE new_gdkdragcontext(GdkDragContext* context);
extern GdkDragContext* get_gdkdragcontext(VALUE context);

extern VALUE make_gdkatom(GdkAtom atom);
extern GdkAtom get_gdkatom(VALUE atom);

/*
 * for GtkArg
 *   RValue: ruby object.
 *   BValue: boxed value of GtkArg.
 */
typedef gpointer (*RValueToBValueFunc)(VALUE);
typedef VALUE (*BValueToRValueFunc)(gpointer);

extern void rbgtk_register_r2b_func(GtkType type, RValueToBValueFunc);
extern void rbgtk_register_b2r_func(GtkType type, BValueToRValueFunc);

extern void rbgtk_arg_init(GtkArg *arg, GtkType type, char *name);
extern void rbgtk_arg_set(GtkArg *arg, VALUE obj);
extern void rbgtk_arg_set_retval(GtkArg *arg, VALUE obj);
extern VALUE rbgtk_arg_get(GtkArg *arg);

//for Clist
#define COMPARE_DEFAULT     0
#define COMPARE_INSENSITIVE 1
#define COMPARE_INT         2
#define COMPARE_FLOAT       3

#endif /* _RBGTK_H */
