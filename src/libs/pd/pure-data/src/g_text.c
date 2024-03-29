/* Copyright (c) 1997-1999 Miller Puckette.
* For information on usage and redistribution, and for a DISCLAIMER OF ALL
* WARRANTIES, see the file, "LICENSE.txt," in this distribution.  */

/* changes by Thomas Musil IEM KUG Graz Austria 2001 */
/* the methods for calling the gui-objects from menu are implemented */
/* all changes are labeled with      iemlib      */

#include <stdlib.h>
#include "m_pd.h"
#include "m_imp.h"
#include "s_stuff.h"

#include "g_canvas.h"
#include <stdio.h>
#include <string.h>
#include <math.h>

#include "s_utf8.h"
#include "g_undo.h"

/* borrowed from RMARGIN and BMARGIN in g_rtext.c */
#define ATOM_RMARGIN 2
#define ATOM_BMARGIN 4 /* 1 pixel smaller than object TMARGIN+BMARGIN */

// mPD
#define MESSAGE_CLICK_WIDTH 3

t_class *text_class;
static t_class *message_class;
static t_class *gatom_class;
static void text_vis(t_gobj *z, t_glist *glist, int vis);
static void text_displace(t_gobj *z, t_glist *glist,
    int dx, int dy);
static void text_getrect(t_gobj *z, t_glist *glist,
    int *xp1, int *yp1, int *xp2, int *yp2);

void canvas_startmotion(t_canvas *x);
int glist_getindex(t_glist *x, t_gobj *y);

/* ----------------- the "text" object.  ------------------ */

    /* add a "text" object (comment) to a glist.  While this one goes for any
    glist, the other 3 below are for canvases only.  (why?)  This is called
    without args if invoked from the GUI; otherwise at least x and y
    are provided.  */

void glist_text(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    t_text *x = (t_text *)pd_new(text_class);
    t_atom at;
    x->te_width = 0;                            /* don't know it yet. */
    x->te_type = T_TEXT;
    x->te_binbuf = binbuf_new();
    if (argc > 1)
    {
        x->te_xpix = atom_getfloatarg(0, argc, argv);
        x->te_ypix = atom_getfloatarg(1, argc, argv);
        if (argc > 2) binbuf_restore(x->te_binbuf, argc-2, argv+2);
        else
        {
            SETSYMBOL(&at, gensym("comment"));
            binbuf_restore(x->te_binbuf, 1, &at);
        }
        glist_add(gl, &x->te_g);
    }
    else
    {
        int xpix, ypix;
        pd_vmess((t_pd *)glist_getcanvas(gl), gensym("editmode"), "i", 1);
        SETSYMBOL(&at, gensym("comment"));
        glist_noselect(gl);
        glist_getnextxy(gl, &xpix, &ypix);
        x->te_xpix = xpix/gl->gl_zoom - 1;
        x->te_ypix = ypix/gl->gl_zoom - 1;
        binbuf_restore(x->te_binbuf, 1, &at);
        glist_add(gl, &x->te_g);
        glist_noselect(gl);
        glist_select(gl, &x->te_g);
            /* it would be nice to "activate" here, but then the second,
            "put-me-down" click changes the text selection, which is quite
            irritating, so I took this back out.  It's OK in messages
            and objects though since there's no text in them at menu
            creation. */
            /* gobj_activate(&x->te_g, gl, 1); */
        if (!canvas_undo_get(glist_getcanvas(gl))->u_doing)
            canvas_undo_add(glist_getcanvas(gl), UNDO_CREATE, "create",
                (void *)canvas_undo_set_create(glist_getcanvas(gl)));
        canvas_startmotion(glist_getcanvas(gl));
    }
}

/* ----------------- the "object" object.  ------------------ */

void canvas_getargs(int *argcp, t_atom **argvp);

static void canvas_objtext(t_glist *gl, int xpix, int ypix, int width,
    int selected, t_binbuf *b)
{
    t_text *x;
    int argc;
    t_atom *argv;
    pd_this->pd_newest = 0;
    canvas_setcurrent((t_canvas *)gl);
    canvas_getargs(&argc, &argv);
    binbuf_eval(b, &pd_objectmaker, argc, argv);
    if (binbuf_getnatom(b))
    {
        if (!pd_this->pd_newest)
            x = 0;
        else if (!(x = pd_checkobject(pd_this->pd_newest)))
        {
            binbuf_print(b);
            error("... didn't return a patchable object");
        }
    }
    else x = 0;
    if (!x)
    {
        x = (t_text *)pd_new(text_class);
        if (binbuf_getnatom(b))
        {
            binbuf_print(b);
            pd_error(x, "... couldn't create");
        }
    }
    x->te_binbuf = b;
    x->te_xpix = xpix;
    x->te_ypix = ypix;
    x->te_width = width;
    x->te_type = T_OBJECT;
    glist_add(gl, &x->te_g);
    if (selected)
    {
            /* this is called if we've been created from the menu. */
        glist_select(gl, &x->te_g);
        gobj_activate(&x->te_g, gl, 1);
    }
    if (pd_class(&x->ob_pd) == vinlet_class)
        canvas_resortinlets(glist_getcanvas(gl));
    if (pd_class(&x->ob_pd) == voutlet_class)
        canvas_resortoutlets(glist_getcanvas(gl));
    canvas_unsetcurrent((t_canvas *)gl);
}

extern int sys_noautopatch;
    /* utility routine to figure out where to put a new text box from menu
    and whether to connect to it automatically */
static void canvas_howputnew(t_canvas *x, int *connectp, int *xpixp, int *ypixp,
    int *indexp, int *totalp)
{
    int xpix, ypix, indx = 0, nobj = 0, n2, x1, x2, y1, y2;
    int connectme = (x->gl_editor->e_selection &&
        !x->gl_editor->e_selection->sel_next && !sys_noautopatch);
    if (connectme)
    {
        t_gobj *g, *selected = x->gl_editor->e_selection->sel_what;
        for (g = x->gl_list, nobj = 0; g; g = g->g_next, nobj++)
            if (g == selected)
        {
            gobj_getrect(g, x, &x1, &y1, &x2, &y2);
            indx = nobj;
            *xpixp = x1 / x->gl_zoom;
            *ypixp = y2  / x->gl_zoom + 5.5;    /* 5 pixels down, rounded */
        }
        glist_noselect(x);
            /* search back for 'selected' and if it isn't on the list,
                plan just to connect from the last item on the list. */
        for (g = x->gl_list, n2 = 0; g; g = g->g_next, n2++)
        {
            if (g == selected)
            {
                indx = n2;
                break;
            }
            else if (!g->g_next)
                indx = nobj-1;
        }
    }
    else
    {
        glist_getnextxy(x, xpixp, ypixp);
        *xpixp = *xpixp/x->gl_zoom - 3;
        *ypixp = *ypixp/x->gl_zoom - 3;
        glist_noselect(x);
    }
    *connectp = connectme;
    *indexp = indx;
    *totalp = nobj;
}

    /* object creation routine.  These are called without any arguments if
    they're invoked from the gui; when pasting or restoring from a file, we
    get at least x and y. */

void canvas_obj(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    t_text *x;
    if (argc >= 2)
    {
        t_binbuf *b = binbuf_new();
        binbuf_restore(b, argc-2, argv+2);
        canvas_objtext(gl, atom_getfloatarg(0, argc, argv),
            atom_getfloatarg(1, argc, argv), 0, 0, b);
    }
        /* JMZ: don't go into interactive mode in a closed canvas */
    else if (!glist_isvisible(gl))
        post("unable to create stub object in closed canvas!");
    else
    {
            /* interactively create new object */
        t_binbuf *b = binbuf_new();
        int connectme, xpix, ypix, indx, nobj;
        canvas_howputnew(gl, &connectme, &xpix, &ypix, &indx, &nobj);
        pd_vmess(&gl->gl_pd, gensym("editmode"), "i", 1);
        canvas_objtext(gl, xpix, ypix, 0, 1, b);
        if (connectme)
            canvas_connect(gl, indx, 0, nobj, 0);
        else canvas_startmotion(glist_getcanvas(gl));
        if (!canvas_undo_get(glist_getcanvas(gl))->u_doing)
            canvas_undo_add(glist_getcanvas(gl), UNDO_CREATE, "create",
                (void *)canvas_undo_set_create(glist_getcanvas(gl)));
    }
}

/* make an object box for an object that's already there. */

/* iemlib */
void canvas_iemguis(t_glist *gl, t_symbol *guiobjname)
{
    t_atom at;
    t_binbuf *b = binbuf_new();
    int xpix, ypix;

    pd_vmess(&gl->gl_pd, gensym("editmode"), "i", 1);
    glist_noselect(gl);
    SETSYMBOL(&at, guiobjname);
    binbuf_restore(b, 1, &at);
    glist_getnextxy(gl, &xpix, &ypix);
    canvas_objtext(gl, xpix/gl->gl_zoom, ypix/gl->gl_zoom, 0, 1, b);
    canvas_startmotion(glist_getcanvas(gl));
    canvas_undo_add(glist_getcanvas(gl), UNDO_CREATE, "create",
        (void *)canvas_undo_set_create(glist_getcanvas(gl)));
}

void canvas_bng(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    canvas_iemguis(gl, gensym("bng"));
}

void canvas_toggle(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    canvas_iemguis(gl, gensym("tgl"));
}

void canvas_vslider(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    canvas_iemguis(gl, gensym("vsl"));
}

void canvas_hslider(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    canvas_iemguis(gl, gensym("hsl"));
}

void canvas_hdial(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    canvas_iemguis(gl, gensym("hdl"));
}

void canvas_vdial(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    canvas_iemguis(gl, gensym("vdl"));
}

void canvas_hradio(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    canvas_iemguis(gl, gensym("hradio"));
}

void canvas_vradio(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    canvas_iemguis(gl, gensym("vradio"));
}

void canvas_vumeter(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    canvas_iemguis(gl, gensym("vu"));
}

void canvas_mycnv(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    canvas_iemguis(gl, gensym("cnv"));
}

void canvas_numbox(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    canvas_iemguis(gl, gensym("nbx"));
}

/* iemlib */

void canvas_objfor(t_glist *gl, t_text *x, int argc, t_atom *argv)
{
    x->te_width = 0;                            /* don't know it yet. */
    x->te_type = T_OBJECT;
    x->te_binbuf = binbuf_new();
    x->te_xpix = atom_getfloatarg(0, argc, argv);
    x->te_ypix = atom_getfloatarg(1, argc, argv);
    if (argc > 2) binbuf_restore(x->te_binbuf, argc-2, argv+2);
    glist_add(gl, &x->te_g);
}

/* ---------------------- the "message" text item ------------------------ */

typedef struct _messresponder
{
    t_pd mr_pd;
    t_outlet *mr_outlet;
} t_messresponder;

typedef struct _message
{
    t_text m_text;
    t_messresponder m_messresponder;
    t_glist *m_glist;
    t_clock *m_clock;
} t_message;

static t_class *message_class, *messresponder_class;

static void messresponder_bang(t_messresponder *x)
{
    outlet_bang(x->mr_outlet);
}

static void messresponder_float(t_messresponder *x, t_float f)
{
    outlet_float(x->mr_outlet, f);
}

static void messresponder_symbol(t_messresponder *x, t_symbol *s)
{
    outlet_symbol(x->mr_outlet, s);
}

static void messresponder_list(t_messresponder *x,
    t_symbol *s, int argc, t_atom *argv)
{
    outlet_list(x->mr_outlet, s, argc, argv);
}

static void messresponder_anything(t_messresponder *x,
    t_symbol *s, int argc, t_atom *argv)
{
    outlet_anything(x->mr_outlet, s, argc, argv);
}

static void message_bang(t_message *x)
{
    binbuf_eval(x->m_text.te_binbuf, &x->m_messresponder.mr_pd, 0, 0);
}

static void message_float(t_message *x, t_float f)
{
    t_atom at;
    SETFLOAT(&at, f);
    binbuf_eval(x->m_text.te_binbuf, &x->m_messresponder.mr_pd, 1, &at);
}

static void message_symbol(t_message *x, t_symbol *s)
{
    t_atom at;
    SETSYMBOL(&at, s);
    binbuf_eval(x->m_text.te_binbuf, &x->m_messresponder.mr_pd, 1, &at);
}

static void message_list(t_message *x, t_symbol *s, int argc, t_atom *argv)
{
    binbuf_eval(x->m_text.te_binbuf, &x->m_messresponder.mr_pd, argc, argv);
}

static void message_set(t_message *x, t_symbol *s, int argc, t_atom *argv)
{
    binbuf_clear(x->m_text.te_binbuf);
    binbuf_add(x->m_text.te_binbuf, argc, argv);
    glist_retext(x->m_glist, &x->m_text);
}

static void message_add2(t_message *x, t_symbol *s, int argc, t_atom *argv)
{
    binbuf_add(x->m_text.te_binbuf, argc, argv);
    glist_retext(x->m_glist, &x->m_text);
}

static void message_add(t_message *x, t_symbol *s, int argc, t_atom *argv)
{
    binbuf_add(x->m_text.te_binbuf, argc, argv);
    binbuf_addsemi(x->m_text.te_binbuf);
    glist_retext(x->m_glist, &x->m_text);
}

static void message_addcomma(t_message *x)
{
    t_atom a;
    SETCOMMA(&a);
    binbuf_add(x->m_text.te_binbuf, 1, &a);
    glist_retext(x->m_glist, &x->m_text);
}

static void message_addsemi(t_message *x)
{
    message_add(x, 0, 0, 0);
}

static void message_adddollar(t_message *x, t_floatarg f)
{
    t_atom a;
    int n = f;
    if (n < 0)
        n = 0;
    SETDOLLAR(&a, n);
    binbuf_add(x->m_text.te_binbuf, 1, &a);
    glist_retext(x->m_glist, &x->m_text);
}

static void message_adddollsym(t_message *x, t_symbol *s)
{
    t_atom a;
    char buf[MAXPDSTRING];
    buf[0] = '$';
    strncpy(buf+1, s->s_name, MAXPDSTRING-2);
    buf[MAXPDSTRING-1] = 0;
    SETDOLLSYM(&a, gensym(buf));
    binbuf_add(x->m_text.te_binbuf, 1, &a);
    glist_retext(x->m_glist, &x->m_text);
}

static void message_click(t_message *x,
    t_floatarg xpos, t_floatarg ypos, t_floatarg shift,
        t_floatarg ctrl, t_floatarg alt)
{
    if (glist_isvisible(x->m_glist))
    {
        /* not zooming click width for now as it gets too fat */
        t_rtext *y = glist_findrtext(x->m_glist, &x->m_text);
        sys_vgui(".x%lx.c itemconfigure %sR -width %d\n",
            glist_getcanvas(x->m_glist), rtext_gettag(y), MESSAGE_CLICK_WIDTH);
        clock_delay(x->m_clock, 120);
    }
    message_float(x, 0);
}

static void message_tick(t_message *x)
{
    if (glist_isvisible(x->m_glist))
    {
        t_rtext *y = glist_findrtext(x->m_glist, &x->m_text);
        sys_vgui(".x%lx.c itemconfigure %sR -width %d\n",
            glist_getcanvas(x->m_glist), rtext_gettag(y),
            glist_getzoom(x->m_glist));
    }
}

static void message_free(t_message *x)
{
    clock_free(x->m_clock);
}

void canvas_msg(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    t_message *x = (t_message *)pd_new(message_class);
    x->m_messresponder.mr_pd = messresponder_class;
    x->m_messresponder.mr_outlet = outlet_new(&x->m_text, &s_float);
    x->m_text.te_width = 0;                             /* don't know it yet. */
    x->m_text.te_type = T_MESSAGE;
    x->m_text.te_binbuf = binbuf_new();
    x->m_glist = gl;
    x->m_clock = clock_new(x, (t_method)message_tick);
    if (argc > 1)
    {
        x->m_text.te_xpix = atom_getfloatarg(0, argc, argv);
        x->m_text.te_ypix = atom_getfloatarg(1, argc, argv);
        if (argc > 2) binbuf_restore(x->m_text.te_binbuf, argc-2, argv+2);
        glist_add(gl, &x->m_text.te_g);
    }
    else if (!glist_isvisible(gl))
        post("unable to create stub message in closed canvas!");
    else
    {
        int connectme, xpix, ypix, indx, nobj;
        canvas_howputnew(gl, &connectme, &xpix, &ypix, &indx, &nobj);

        pd_vmess(&gl->gl_pd, gensym("editmode"), "i", 1);
        x->m_text.te_xpix = xpix;
        x->m_text.te_ypix = ypix;
        glist_add(gl, &x->m_text.te_g);
        glist_noselect(gl);
        glist_select(gl, &x->m_text.te_g);
        gobj_activate(&x->m_text.te_g, gl, 1);
        if (connectme)
            canvas_connect(gl, indx, 0, nobj, 0);
        else canvas_startmotion(glist_getcanvas(gl));
        canvas_undo_add(glist_getcanvas(gl), UNDO_CREATE, "create",
            (void *)canvas_undo_set_create(glist_getcanvas(gl)));
    }
}

/* ---------------------- the "atom" text item ------------------------ */

#define ATOMBUFSIZE 40
#define ATOM_LABELLEFT 0
#define ATOM_LABELRIGHT 1
#define ATOM_LABELUP 2
#define ATOM_LABELDOWN 3

typedef struct _gatom
{
    t_text a_text;
    t_atom a_atom;          /* this holds the value and the type */
    t_glist *a_glist;       /* owning glist */
    t_float a_toggle;       /* value to toggle to */
    t_float a_draghi;       /* high end of drag range */
    t_float a_draglo;       /* low end of drag range */
    t_symbol *a_label;      /* symbol to show as label next to box */
    t_symbol *a_symfrom;    /* "receive" name -- bind ourselves to this */
    t_symbol *a_symto;      /* "send" name -- send to this on output */
    char a_buf[ATOMBUFSIZE];/* string buffer for typing */
    unsigned int a_shift:1;         /* was shift key down when drag started? */
    unsigned int a_wherelabel:2;    /* 0-3 for left, right, above, below */
    unsigned int a_grabbed:1;       /* 1 if we've grabbed keyboard */
    t_symbol *a_expanded_to; /* a_symto after $0, $1, ...  expansion */
} t_gatom;

    /* prepend "-" as necessary to avoid empty strings, so we can
    use them in Pd messages.  A more complete solution would be
    to introduce some quoting mechanism; but then we'd be much more
    complicated. */
static t_symbol *gatom_escapit(t_symbol *s)
{
    if (!*s->s_name)
        return (gensym("-"));
    else if (*s->s_name == '-')
    {
        char shmo[100];
        shmo[0] = '-';
        strncpy(shmo+1, s->s_name, 99);
        shmo[99] = 0;
        return (gensym(shmo));
    }
    else return (iemgui_dollar2raute(s));
}

    /* undo previous operation: strip leading "-" if found. */
static t_symbol *gatom_unescapit(t_symbol *s)
{
    if (*s->s_name == '-')
        return (gensym(s->s_name+1));
    else return (iemgui_raute2dollar(s));
}

static void gatom_redraw(t_gobj *client, t_glist *glist)
{
    t_gatom *x = (t_gatom *)client;
    glist_retext(x->a_glist, &x->a_text);
}

static void gatom_retext(t_gatom *x, int senditup)
{
    binbuf_clear(x->a_text.te_binbuf);
    binbuf_add(x->a_text.te_binbuf, 1, &x->a_atom);
    if (senditup && glist_isvisible(x->a_glist)
        && gobj_shouldvis(&x->a_text.te_g, x->a_glist))
            sys_queuegui(x, x->a_glist, gatom_redraw);
}

#ifdef _MSC_VER
#include <float.h>
#define isnan _isnan
#endif

static void gatom_set(t_gatom *x, t_symbol *s, int argc, t_atom *argv)
{
    t_atom oldatom = x->a_atom;
    int changed = 0;
    if (!argc) return;
    if (x->a_atom.a_type == A_FLOAT)
    {
        x->a_atom.a_w.w_float = atom_getfloat(argv);
        changed = ((x->a_atom.a_w.w_float != oldatom.a_w.w_float));
        if (isnan(x->a_atom.a_w.w_float) != isnan(oldatom.a_w.w_float))
            changed = 1;
    }
    else if (x->a_atom.a_type == A_SYMBOL)
        x->a_atom.a_w.w_symbol = atom_getsymbol(argv),
            changed = (x->a_atom.a_w.w_symbol != oldatom.a_w.w_symbol);
    if (changed)
        gatom_retext(x, 1);
    x->a_buf[0] = 0;
}

static void gatom_bang(t_gatom *x)
{
    if (x->a_atom.a_type == A_FLOAT)
    {
        if (x->a_text.te_outlet)
            outlet_float(x->a_text.te_outlet, x->a_atom.a_w.w_float);
        if (*x->a_expanded_to->s_name && x->a_expanded_to->s_thing)
        {
            if (x->a_symto == x->a_symfrom)
                pd_error(x,
                    "%s: atom with same send/receive name (infinite loop)",
                        x->a_symto->s_name);
            else pd_float(x->a_expanded_to->s_thing, x->a_atom.a_w.w_float);
        }
    }
    else if (x->a_atom.a_type == A_SYMBOL)
    {
        if (x->a_text.te_outlet)
            outlet_symbol(x->a_text.te_outlet, x->a_atom.a_w.w_symbol);
        if (*x->a_symto->s_name && x->a_expanded_to->s_thing)
        {
            if (x->a_symto == x->a_symfrom)
                pd_error(x,
                    "%s: atom with same send/receive name (infinite loop)",
                        x->a_symto->s_name);
            else pd_symbol(x->a_expanded_to->s_thing, x->a_atom.a_w.w_symbol);
        }
    }
}

static void gatom_float(t_gatom *x, t_float f)
{
    t_atom at;
    SETFLOAT(&at, f);
    gatom_set(x, 0, 1, &at);
    gatom_bang(x);
}

static void gatom_clipfloat(t_gatom *x, t_float f)
{
    if (x->a_draglo != 0 || x->a_draghi != 0)
    {
        if (f < x->a_draglo)
            f = x->a_draglo;
        if (f > x->a_draghi)
            f = x->a_draghi;
    }
    gatom_float(x, f);
}

static void gatom_symbol(t_gatom *x, t_symbol *s)
{
    t_atom at;
    SETSYMBOL(&at, s);
    gatom_set(x, 0, 1, &at);
    gatom_bang(x);
}

    /* We need a list method because, since there's both an "inlet" and a
    "nofirstin" flag, the standard list behavior gets confused. */
static void gatom_list(t_gatom *x, t_symbol *s, int argc, t_atom *argv)
{
    if (!argc)
        gatom_bang(x);
    else if (argv->a_type == A_FLOAT)
        gatom_float(x, argv->a_w.w_float);
    else if (argv->a_type == A_SYMBOL)
        gatom_symbol(x, argv->a_w.w_symbol);
    else pd_error(x, "gatom_list: need float or symbol");
}

static void gatom_motion(void *z, t_floatarg dx, t_floatarg dy)
{
    t_gatom *x = (t_gatom *)z;
    if (dy == 0) return;
    if (x->a_atom.a_type == A_FLOAT)
    {
        if (x->a_shift)
        {
            double nval = x->a_atom.a_w.w_float - 0.01 * dy;
            double trunc = 0.01 * (floor(100. * nval + 0.5));
            if (trunc < nval + 0.0001 && trunc > nval - 0.0001) nval = trunc;
            gatom_clipfloat(x, nval);
        }
        else
        {
            double nval = x->a_atom.a_w.w_float - dy;
            double trunc = 0.01 * (floor(100. * nval + 0.5));
            if (trunc < nval + 0.0001 && trunc > nval - 0.0001) nval = trunc;
            trunc = floor(nval + 0.5);
            if (trunc < nval + 0.001 && trunc > nval - 0.001) nval = trunc;
            gatom_clipfloat(x, nval);
        }
    }
}

static void gatom_reborder(t_gatom *x)
{
    t_rtext *y = glist_findrtext(x->a_glist, &x->a_text);
    text_drawborder(&x->a_text, x->a_glist, rtext_gettag(y),
        rtext_width(y), rtext_height(y), 0);
}

static void gatom_key(void *z, t_floatarg f)
{
    t_gatom *x = (t_gatom *)z;
    int c = f;
    int len = (int)strlen(x->a_buf);
    t_atom at;
    char sbuf[ATOMBUFSIZE + 4];
    if (c == 0)
    {
        /* we're being notified that no more keys will come for this grab */
        x->a_grabbed = 0;
        gatom_reborder(x);
        gatom_retext(x, 1);
        gatom_redraw(&x->a_text.te_g, x->a_glist);
        return;
    }
    else if (c == '\b')
    {
        if (len > 0)
        {
            /* walk back multi-byte chars when needed */
            int i = len;
            u8_dec(x->a_buf, &i);
            x->a_buf[i] = 0;
        }
        goto redraw;
    }
    else if (c == '\n')
    {
        if (x->a_atom.a_type == A_FLOAT)
            x->a_atom.a_w.w_float = atof(x->a_buf);
        else if (x->a_atom.a_type == A_SYMBOL)
            x->a_atom.a_w.w_symbol = gensym(x->a_buf);
        else bug("gatom_key");
        gatom_bang(x);
        gatom_retext(x, 1);
        x->a_buf[0] = 0;
    }
    else if (len < (ATOMBUFSIZE-1))
    {
            /* for numbers, only let reasonable characters through */
        if ((x->a_atom.a_type == A_SYMBOL) ||
            ((c >= '0' && c <= '9') || c == '.' || c == '-'
                || c == 'e' || c == 'E'))
        {
            /* the wchar could expand to up to 4 bytes, which
             * which might overrun our a_buf;
             * therefore we first expand into a temporary buffer,
             * and only if the resulting utf8 string fits into a_buf
             * we apply it
             */
            char utf8[UTF8_MAXBYTES];
            int utf8len = u8_wc_toutf8(utf8, c);
            if((len+utf8len) < (ATOMBUFSIZE-1))
            {
                int j=0;
                for(j=0; j<utf8len; j++)
                    x->a_buf[len+j] = utf8[j];

                x->a_buf[len+utf8len] = 0;
            }
            goto redraw;
        }
    }
    return;
redraw:
        /* LATER figure out how to avoid creating all these symbols! */
    sprintf(sbuf, "%s...", x->a_buf);
    SETSYMBOL(&at, gensym(sbuf));
    binbuf_clear(x->a_text.te_binbuf);
    binbuf_add(x->a_text.te_binbuf, 1, &at);
    glist_retext(x->a_glist, &x->a_text);
}

static void gatom_click(t_gatom *x,
    t_floatarg xpos, t_floatarg ypos, t_floatarg shift, t_floatarg ctrl,
    t_floatarg alt)
{
    if (x->a_text.te_width == 1)
    {
        if (x->a_atom.a_type == A_FLOAT)
            gatom_float(x, (x->a_atom.a_w.w_float == 0));
    }
    else
    {
        if (alt)
        {
            if (x->a_atom.a_type != A_FLOAT) return;
            if (x->a_atom.a_w.w_float != 0)
            {
                x->a_toggle = x->a_atom.a_w.w_float;
                gatom_float(x, 0);
                return;
            }
            else gatom_float(x, x->a_toggle);
        }
        x->a_shift = shift;
        x->a_grabbed = 1;
        gatom_reborder(x);
        x->a_buf[0] = 0;
        glist_grab(x->a_glist, &x->a_text.te_g, gatom_motion, gatom_key,
            xpos, ypos);
    }
}

    /* message back from dialog window */
static void gatom_param(t_gatom *x, t_symbol *sel, int argc, t_atom *argv)
{
    t_float width = atom_getfloatarg(0, argc, argv);
    t_float draglo = atom_getfloatarg(1, argc, argv);
    t_float draghi = atom_getfloatarg(2, argc, argv);
    t_symbol *label = gatom_unescapit(atom_getsymbolarg(3, argc, argv));
    t_float wherelabel = atom_getfloatarg(4, argc, argv);
    t_symbol *symfrom = gatom_unescapit(atom_getsymbolarg(5, argc, argv));
    t_symbol *symto = gatom_unescapit(atom_getsymbolarg(6, argc, argv));

    gobj_vis(&x->a_text.te_g, x->a_glist, 0);
    if (!*symfrom->s_name && *x->a_symfrom->s_name)
        inlet_new(&x->a_text, &x->a_text.te_pd, 0, 0);
    else if (*symfrom->s_name && !*x->a_symfrom->s_name && x->a_text.te_inlet)
    {
        canvas_deletelinesforio(x->a_glist, &x->a_text,
            x->a_text.te_inlet, 0);
        inlet_free(x->a_text.te_inlet);
    }
    if (!*symto->s_name && *x->a_symto->s_name)
        outlet_new(&x->a_text, 0);
    else if (*symto->s_name && !*x->a_symto->s_name && x->a_text.te_outlet)
    {
        canvas_deletelinesforio(x->a_glist, &x->a_text,
            0, x->a_text.te_outlet);
        outlet_free(x->a_text.te_outlet);
    }
    if (draglo >= draghi)
        draglo = draghi = 0;
    x->a_draglo = draglo;
    x->a_draghi = draghi;
    if (width < 0)
        width = 4;
    else if (width > 80)
        width = 80;
    x->a_text.te_width = width;
    x->a_wherelabel = ((int)wherelabel & 3);
    x->a_label = label;
    if (*x->a_symfrom->s_name)
        pd_unbind(&x->a_text.te_pd,
            canvas_realizedollar(x->a_glist, x->a_symfrom));
    x->a_symfrom = symfrom;
    if (*x->a_symfrom->s_name)
        pd_bind(&x->a_text.te_pd,
            canvas_realizedollar(x->a_glist, x->a_symfrom));
    x->a_symto = symto;
    x->a_expanded_to = canvas_realizedollar(x->a_glist, x->a_symto);
    gobj_vis(&x->a_text.te_g, x->a_glist, 1);
    canvas_dirty(x->a_glist, 1);

    /* glist_retext(x->a_glist, &x->a_text); */
}

    /* ---------------- gatom-specific widget functions --------------- */
static void gatom_getwherelabel(t_gatom *x, t_glist *glist, int *xp, int *yp)
{
    int x1, y1, x2, y2;
    int zoom = glist_getzoom(glist);
    text_getrect(&x->a_text.te_g, glist, &x1, &y1, &x2, &y2);
    if (x->a_wherelabel == ATOM_LABELLEFT)
    {
        *xp = x1 - 3 * zoom - (
            (int)strlen(canvas_realizedollar(x->a_glist, x->a_label)->s_name) *
            glist_fontwidth(glist));
        *yp = y1 + 2 * zoom;
    }
    else if (x->a_wherelabel == ATOM_LABELRIGHT)
    {
        *xp = x2 + 2 * zoom;
        *yp = y1 + 2 * zoom;
    }
    else if (x->a_wherelabel == ATOM_LABELUP)
    {
        *xp = x1 - 1 * zoom;
        *yp = y1 - 1 * zoom - glist_fontheight(glist);
    }
    else
    {
        *xp = x1 - 1 * zoom;
        *yp = y2 + 3 * zoom;
    }
}

static void gatom_displace(t_gobj *z, t_glist *glist,
    int dx, int dy)
{
    // mPD
    if (dx == 0 && dy == 0){
        return;
    }

    t_gatom *x = (t_gatom*)z;
    text_displace(z, glist, dx, dy);
    sys_vgui(".x%lx.c move %lx.l %d %d\n", glist_getcanvas(glist),
        x, dx * glist->gl_zoom, dy * glist->gl_zoom);
}

static void gatom_vis(t_gobj *z, t_glist *glist, int vis)
{
    t_gatom *x = (t_gatom*)z;
    text_vis(z, glist, vis);
    if (*x->a_label->s_name)
    {
        if (vis)
        {
            int x1, y1;
            gatom_getwherelabel(x, glist, &x1, &y1);
            sys_vgui("pdtk_text_new .x%lx.c {%lx.l label text} %f %f {%s } %d %s\n",
                glist_getcanvas(glist), x,
                (double)x1, (double)y1,
                canvas_realizedollar(x->a_glist, x->a_label)->s_name,
                sys_hostfontsize(glist_getfont(glist), glist_getzoom(glist)),
                "black");
        }
        else sys_vgui(".x%lx.c delete %lx.l\n", glist_getcanvas(glist), x);
    }
    if (!vis)
        sys_unqueuegui(x);
}

void canvas_atom(t_glist *gl, t_atomtype type,
    t_symbol *s, int argc, t_atom *argv)
{
    t_gatom *x = (t_gatom *)pd_new(gatom_class);
    t_atom at;
    x->a_text.te_width = 0;                        /* don't know it yet. */
    x->a_text.te_type = T_ATOM;
    x->a_text.te_binbuf = binbuf_new();
    x->a_glist = gl;
    x->a_atom.a_type = type;
    x->a_toggle = 1;
    x->a_draglo = 0;
    x->a_draghi = 0;
    x->a_wherelabel = 0;
    x->a_label = &s_;
    x->a_symfrom = &s_;
    x->a_symto = x->a_expanded_to = &s_;
    x->a_grabbed = 0;
    if (type == A_FLOAT)
    {
        x->a_atom.a_w.w_float = 0;
        x->a_text.te_width = 5;
        SETFLOAT(&at, 0);
    }
    else
    {
        x->a_atom.a_w.w_symbol = &s_symbol;
        x->a_text.te_width = 10;
        SETSYMBOL(&at, &s_symbol);
    }
    binbuf_add(x->a_text.te_binbuf, 1, &at);
    if (argc > 1)
        /* create from file. x, y, width, low-range, high-range, flags,
            label, receive-name, send-name */
    {
        x->a_text.te_xpix = atom_getfloatarg(0, argc, argv);
        x->a_text.te_ypix = atom_getfloatarg(1, argc, argv);
        x->a_text.te_width = atom_getfloatarg(2, argc, argv);
            /* sanity check because some very old patches have trash in this
            field... remove this in 2003 or so: */
        if (x->a_text.te_width < 0 || x->a_text.te_width > 500)
            x->a_text.te_width = 4;
        x->a_draglo = atom_getfloatarg(3, argc, argv);
        x->a_draghi = atom_getfloatarg(4, argc, argv);
        x->a_wherelabel = (((int)atom_getfloatarg(5, argc, argv)) & 3);
        x->a_label = gatom_unescapit(atom_getsymbolarg(6, argc, argv));
        x->a_symfrom = gatom_unescapit(atom_getsymbolarg(7, argc, argv));
        if (*x->a_symfrom->s_name)
            pd_bind(&x->a_text.te_pd,
                canvas_realizedollar(x->a_glist, x->a_symfrom));

        x->a_symto = gatom_unescapit(atom_getsymbolarg(8, argc, argv));
        x->a_expanded_to = canvas_realizedollar(x->a_glist, x->a_symto);
        if (x->a_symto == &s_)
            outlet_new(&x->a_text,
                x->a_atom.a_type == A_FLOAT ? &s_float: &s_symbol);
        if (x->a_symfrom == &s_)
            inlet_new(&x->a_text, &x->a_text.te_pd, 0, 0);
        glist_add(gl, &x->a_text.te_g);
    }
    else
    {
        int connectme, xpix, ypix, indx, nobj;
        canvas_howputnew(gl, &connectme, &xpix, &ypix, &indx, &nobj);
        outlet_new(&x->a_text,
            x->a_atom.a_type == A_FLOAT ? &s_float: &s_symbol);
        inlet_new(&x->a_text, &x->a_text.te_pd, 0, 0);
        pd_vmess(&gl->gl_pd, gensym("editmode"), "i", 1);
        x->a_text.te_xpix = xpix;
        x->a_text.te_ypix = ypix;
        glist_add(gl, &x->a_text.te_g);
        glist_noselect(gl);
        glist_select(gl, &x->a_text.te_g);
        if (connectme)
            canvas_connect(gl, indx, 0, nobj, 0);
        else canvas_startmotion(glist_getcanvas(gl));
        canvas_undo_add(glist_getcanvas(gl), UNDO_CREATE, "create",
            (void *)canvas_undo_set_create(glist_getcanvas(gl)));
    }
}

void canvas_floatatom(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    canvas_atom(gl, A_FLOAT, s, argc, argv);
}

void canvas_symbolatom(t_glist *gl, t_symbol *s, int argc, t_atom *argv)
{
    canvas_atom(gl, A_SYMBOL, s, argc, argv);
}

static void gatom_free(t_gatom *x)
{
    if (*x->a_symfrom->s_name)
        pd_unbind(&x->a_text.te_pd,
            canvas_realizedollar(x->a_glist, x->a_symfrom));
    gfxstub_deleteforkey(x);
}

static void gatom_properties(t_gobj *z, t_glist *owner)
{
    t_gatom *x = (t_gatom *)z;
    char buf[200];
    sprintf(buf, "pdtk_gatom_dialog %%s %d %g %g %d {%s} {%s} {%s}\n",
        x->a_text.te_width, x->a_draglo, x->a_draghi,
            x->a_wherelabel, gatom_escapit(x->a_label)->s_name,
                gatom_escapit(x->a_symfrom)->s_name,
                    gatom_escapit(x->a_symto)->s_name);
    gfxstub_new(&x->a_text.te_pd, x, buf);
}


/* -------------------- widget behavior for text objects ------------ */

static void text_getrect(t_gobj *z, t_glist *glist,
    int *xp1, int *yp1, int *xp2, int *yp2)
{
    t_text *x = (t_text *)z;
    int width, height, iscomment = (x->te_type == T_TEXT);
    t_float x1, y1, x2, y2;

        /* for number boxes, we know width and height a priori, and should
        report them here so that graphs can get swelled to fit. */

    if (x->te_type == T_ATOM && x->te_width > 0)
    {
        width = (x->te_width > 0 ? x->te_width : 6) * glist_fontwidth(glist);
        height = glist_fontheight(glist);
        if (glist_getzoom(glist) > 1)
        {
            /* zoom margins */
            width += ATOM_RMARGIN * glist_getzoom(glist);
            height += ATOM_BMARGIN * glist_getzoom(glist);
        }
        else
        {
            width += ATOM_RMARGIN;
            height += ATOM_BMARGIN;
        }
    }
        /* if we're invisible we don't know our size so we just lie about
        it.  This is called on invisible boxes to establish order of inlets
        and possibly other reasons.
           To find out if the box is visible we can't just check the "vis"
        flag because we might be within the vis() routine and not have set
        that yet.  So we check directly whether the "rtext" list has been
        built.  LATER reconsider when "vis" flag should be on and off? */

    else if (glist->gl_editor && glist->gl_editor->e_rtext)
    {
        t_rtext *y = glist_findrtext(glist, x);
        width = rtext_width(y);
        height = rtext_height(y) - (iscomment << 1);
    }
    else width = height = 10;
    x1 = text_xpix(x, glist);
    y1 = text_ypix(x, glist);
    x2 = x1 + width;
    y2 = y1 + height;
    y1 += iscomment;
    *xp1 = x1;
    *yp1 = y1;
    *xp2 = x2;
    *yp2 = y2;
}

static void text_displace(t_gobj *z, t_glist *glist,
    int dx, int dy)
{
    t_text *x = (t_text *)z;
    x->te_xpix += dx;
    x->te_ypix += dy;
    if (glist_isvisible(glist))
    {
        t_rtext *y = glist_findrtext(glist, x);
        rtext_displace(y, glist->gl_zoom * dx, glist->gl_zoom * dy);
        text_drawborder(x, glist, rtext_gettag(y),
            rtext_width(y), rtext_height(y), 0);
        canvas_fixlinesfor(glist, x);
    }
}

static void text_select(t_gobj *z, t_glist *glist, int state)
{
    t_text *x = (t_text *)z;
    t_rtext *y = glist_findrtext(glist, x);
    rtext_select(y, state);
    if (glist_isvisible(glist) && gobj_shouldvis(&x->te_g, glist))
        sys_vgui(".x%lx.c itemconfigure %sR -fill %s\n", glist,
            rtext_gettag(y), (state? "blue" : "black"));
}

static void text_activate(t_gobj *z, t_glist *glist, int state)
{
    t_text *x = (t_text *)z;
    t_rtext *y = glist_findrtext(glist, x);
    if (z->g_pd != gatom_class) rtext_activate(y, state);
}

static void text_delete(t_gobj *z, t_glist *glist)
{
    t_text *x = (t_text *)z;
        canvas_deletelinesfor(glist, x);
}

static void text_vis(t_gobj *z, t_glist *glist, int vis)
{
    t_text *x = (t_text *)z;
    if (vis)
    {
        if (gobj_shouldvis(&x->te_g, glist))
        {
            t_rtext *y = glist_findrtext(glist, x);
            if (x->te_type == T_ATOM)
                glist_retext(glist, x);
            text_drawborder(x, glist, rtext_gettag(y),
                rtext_width(y), rtext_height(y), 1);
            rtext_draw(y);
        }
    }
    else
    {
        t_rtext *y = glist_findrtext(glist, x);
        if (gobj_shouldvis(&x->te_g, glist))
        {
            text_eraseborder(x, glist, rtext_gettag(y));
            rtext_erase(y);
        }
    }
}

static int text_click(t_gobj *z, struct _glist *glist,
    int xpix, int ypix, int shift, int alt, int dbl, int doit)
{
    t_text *x = (t_text *)z;
    if (x->te_type == T_OBJECT)
    {
        t_symbol *clicksym = gensym("click");
        if (zgetfn(&x->te_pd, clicksym))
        {
            if (doit)
                pd_vmess(&x->te_pd, clicksym, "fffff",
                    (double)xpix, (double)ypix,
                        (double)shift, (double)0, (double)alt);
            return (1);
        }
        else return (0);
    }
    else if (x->te_type == T_ATOM)
    {
        if (doit)
            gatom_click((t_gatom *)x, (t_floatarg)xpix, (t_floatarg)ypix,
                (t_floatarg)shift, (t_floatarg)0, (t_floatarg)alt);
        return (1);
    }
    else if (x->te_type == T_MESSAGE)
    {
        if (doit)
            message_click((t_message *)x, (t_floatarg)xpix, (t_floatarg)ypix,
                (t_floatarg)shift, (t_floatarg)0, (t_floatarg)alt);
        return (1);
    }
    else return (0);
}

void canvas_statesavers_doit(t_glist *x, t_binbuf *b);
void text_save(t_gobj *z, t_binbuf *b)
{
    t_text *x = (t_text *)z;
    if (x->te_type == T_OBJECT)
    {
            /* if we have a "saveto" method, and if we don't happen to be
            a canvas that's an abstraction, the saveto method does the work */
        if (zgetfn(&x->te_pd, gensym("saveto")) &&
            !((pd_class(&x->te_pd) == canvas_class) &&
                (canvas_isabstraction((t_canvas *)x)
                    || canvas_istable((t_canvas *)x))))
        {
            mess1(&x->te_pd, gensym("saveto"), b);
            binbuf_addv(b, "ssii", gensym("#X"), gensym("restore"),
                (int)x->te_xpix, (int)x->te_ypix);
            binbuf_addbinbuf(b, x->te_binbuf);
            binbuf_addv(b, ";");
            if (x->te_width)
                binbuf_addv(b, "ssi;",
                    gensym("#X"), gensym("f"), (int)x->te_width);
        }
        else    /* otherwise just save the text */
        {
            binbuf_addv(b, "ssii", gensym("#X"), gensym("obj"),
                (int)x->te_xpix, (int)x->te_ypix);
            binbuf_addbinbuf(b, x->te_binbuf);
            if (x->te_width)
                binbuf_addv(b, ",si", gensym("f"), (int)x->te_width);
            binbuf_addv(b, ";");
        }
            /* if an abstraction, give it a chance to save state */
        if (pd_class(&x->te_pd) == canvas_class &&
            canvas_isabstraction((t_canvas *)x))
                canvas_statesavers_doit((t_glist *)x, b);
    }
    else if (x->te_type == T_MESSAGE)
    {
        binbuf_addv(b, "ssii", gensym("#X"), gensym("msg"),
            (int)x->te_xpix, (int)x->te_ypix);
        binbuf_addbinbuf(b, x->te_binbuf);
        if (x->te_width)
            binbuf_addv(b, ",si", gensym("f"), (int)x->te_width);
        binbuf_addv(b, ";");
    }
    else if (x->te_type == T_ATOM)
    {
        t_atomtype t = ((t_gatom *)x)->a_atom.a_type;
        t_symbol *sel = (t == A_SYMBOL ? gensym("symbolatom") :
            (t == A_FLOAT ? gensym("floatatom") : gensym("intatom")));
        t_symbol *label = gatom_escapit(((t_gatom *)x)->a_label);
        t_symbol *symfrom = gatom_escapit(((t_gatom *)x)->a_symfrom);
        t_symbol *symto = gatom_escapit(((t_gatom *)x)->a_symto);
        binbuf_addv(b, "ssiiifffsss;", gensym("#X"), sel,
            (int)x->te_xpix, (int)x->te_ypix, (int)x->te_width,
            (double)((t_gatom *)x)->a_draglo,
            (double)((t_gatom *)x)->a_draghi,
            (double)((t_gatom *)x)->a_wherelabel,
            label, symfrom, symto);
    }
    else
    {
        binbuf_addv(b, "ssii", gensym("#X"), gensym("text"),
            (int)x->te_xpix, (int)x->te_ypix);
        binbuf_addbinbuf(b, x->te_binbuf);
        if (x->te_width)
            binbuf_addv(b, ",si", gensym("f"), (int)x->te_width);
        binbuf_addv(b, ";");
    }
}

    /* this one is for everyone but "gatoms"; it's imposed in m_class.c */
const t_widgetbehavior text_widgetbehavior =
{
    text_getrect,
    text_displace,
    text_select,
    text_activate,
    text_delete,
    text_vis,
    text_click,
};

static const t_widgetbehavior gatom_widgetbehavior =
{
    text_getrect,
    gatom_displace,
    text_select,
    text_activate,
    text_delete,
    gatom_vis,
    text_click,
};

/* -------------------- the "text" class  ------------ */

    /* draw inlets and outlets for a text object or for a graph. */
void glist_drawiofor(t_glist *glist, t_object *ob, int firsttime,
    const char *tag, int x1, int y1, int x2, int y2)
{
    int n = obj_noutlets(ob), nplus = (n == 1 ? 1 : n-1), i;
    int width = x2 - x1;
    int iow = IOWIDTH * glist->gl_zoom;
    int ih = IHEIGHT * glist->gl_zoom, oh = OHEIGHT * glist->gl_zoom;
    /* draw over border, so assume border width = 1 pixel * glist->gl_zoom */
    for (i = 0; i < n; i++)
    {
        // mPD
        const char* signalTag = obj_issignaloutlet(ob, i) ? "signal" : "control";
        int onset = x1 + (width - iow) * i / nplus;
        if (firsttime)
            sys_vgui(".x%lx.c create rectangle %d %d %d %d "
                "-tags [list %so%d outlet %s] -fill black\n", // mPD
                glist_getcanvas(glist),
                onset, y2 - oh + glist->gl_zoom,
                onset + iow, y2,
                tag, i, signalTag); // mPD
        else
            sys_vgui(".x%lx.c coords %so%d %d %d %d %d\n",
                glist_getcanvas(glist), tag, i,
                onset, y2 - oh + glist->gl_zoom,
                onset + iow, y2);
    }
    n = obj_ninlets(ob);
    nplus = (n == 1 ? 1 : n-1);
    for (i = 0; i < n; i++)
    {
        // mPD
        const char* signalTag = obj_issignalinlet(ob, i) ? "signal" : "control";
        int onset = x1 + (width - iow) * i / nplus;
        if (firsttime)
            sys_vgui(".x%lx.c create rectangle %d %d %d %d "
                "-tags [list %si%d inlet %s] -fill black\n", // mPD
                glist_getcanvas(glist),
                onset, y1,
                onset + iow, y1 + ih - glist->gl_zoom,
                tag, i, signalTag);// mPD
        else
            sys_vgui(".x%lx.c coords %si%d %d %d %d %d\n",
                glist_getcanvas(glist), tag, i,
                onset, y1,
                onset + iow, y1 + ih - glist->gl_zoom);
    }
}

void text_drawborder(t_text *x, t_glist *glist,
    const char *tag, int width2, int height2, int firsttime)
{
    t_object *ob;
    int x1, y1, x2, y2, width, height, corner;
    text_getrect(&x->te_g, glist, &x1, &y1, &x2, &y2);
    width = x2 - x1;
    height = y2 - y1;
    if (x->te_type == T_OBJECT)
    {
        char *pattern = ((pd_class(&x->te_pd) == text_class) ? "-" : "\"\"");
        if (firsttime)
            sys_vgui(".x%lx.c create line %d %d %d %d %d %d %d %d %d %d "
                "-dash %s -width %d -capstyle projecting "
                "-tags [list %sR obj]\n",
                glist_getcanvas(glist),
                x1, y1,  x2, y1,  x2, y2,  x1, y2,  x1, y1,  pattern,
                glist->gl_zoom, tag);
        else
        {
            sys_vgui(".x%lx.c coords %sR %d %d %d %d %d %d %d %d %d %d\n",
                glist_getcanvas(glist), tag,
                x1, y1,  x2, y1,  x2, y2,  x1, y2,  x1, y1);
            sys_vgui(".x%lx.c itemconfigure %sR -dash %s\n",
                glist_getcanvas(glist), tag, pattern);
        }
    }
    else if (x->te_type == T_MESSAGE)
    {
        corner = ((y2-y1)/4);
        if (corner > 10*glist->gl_zoom)
            corner = 10*glist->gl_zoom; /* looks bad if too big */
        if (firsttime)
            sys_vgui(".x%lx.c create line "
                "%d %d %d %d %d %d %d %d %d %d %d %d %d %d "
                "-width %d -capstyle projecting -tags [list %sR msg]\n",
                glist_getcanvas(glist),
                x1, y1,  x2+corner, y1,  x2, y1+corner,  x2,
                y2-corner,  x2+corner, y2, x1, y2,  x1, y1,
                glist->gl_zoom, tag);
        else
            sys_vgui(".x%lx.c coords %sR "
            "%d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
                glist_getcanvas(glist), tag,
                x1, y1,  x2+corner, y1,  x2, y1+corner,  x2,
                y2-corner,  x2+corner, y2, x1, y2,  x1, y1);
    }
    else if (x->te_type == T_ATOM)
    {
        // mPD
        int grabbed = 0; // glist->gl_zoom * ((t_gatom *)x)->a_grabbed;

        int x1p = x1 + grabbed, y1p = y1 + grabbed;
        corner = ((y2-y1)/4);
        if (firsttime)
            sys_vgui(".x%lx.c create line %d %d %d %d %d %d %d %d %d %d %d %d "
                "-width %d -capstyle projecting -tags [list %sR atom]\n",
                glist_getcanvas(glist),
                x1p, y1p,  x2-corner, y1p,  x2, y1p+corner, x2, y2,
                    x1p, y2,  x1p, y1p, glist->gl_zoom+grabbed, tag);
        else
        {
            sys_vgui(".x%lx.c coords %sR %d %d %d %d %d %d %d %d %d %d %d %d\n",
                glist_getcanvas(glist), tag,
                x1p, y1p,  x2-corner, y1p,  x2, y1p+corner,  x2, y2,
                    x1p, y2,  x1p, y1p);
            // mPD
            /* sys_vgui(".x%lx.c itemconfigure %sR -width %d\n", */
            /*     glist_getcanvas(glist), tag, glist->gl_zoom+grabbed); */
        }
    }
        /* for comments, just draw a bar on RHS if unlocked; when a visible
        canvas is unlocked we have to call this anew on all comments, and when
        locked we erase them all via the annoying "commentbar" tag. */
    else if (x->te_type == T_TEXT && glist->gl_edit)
    {
        if (firsttime)
            sys_vgui(".x%lx.c create line %d %d %d %d "
            "-tags [list %sR commentbar]\n",
                glist_getcanvas(glist),
                x2, y1,  x2, y2, tag);
        else
            sys_vgui(".x%lx.c coords %sR %d %d %d %d\n",
                glist_getcanvas(glist), tag, x2, y1,  x2, y2);
    }
        /* draw inlets/outlets */

    if ((ob = pd_checkobject(&x->te_pd)))
        glist_drawiofor(glist, ob, firsttime, tag, x1, y1, x2, y2);
    if (firsttime) /* raise cords over everything else */
        sys_vgui(".x%lx.c raise cord\n", glist_getcanvas(glist));
}

void glist_eraseiofor(t_glist *glist, t_object *ob, const char *tag)
{
    int i, n;
    n = obj_noutlets(ob);
    for (i = 0; i < n; i++)
        sys_vgui(".x%lx.c delete %so%d\n",
            glist_getcanvas(glist), tag, i);
    n = obj_ninlets(ob);
    for (i = 0; i < n; i++)
        sys_vgui(".x%lx.c delete %si%d\n",
            glist_getcanvas(glist), tag, i);
}

void text_eraseborder(t_text *x, t_glist *glist, const char *tag)
{
    if (x->te_type == T_TEXT && !glist->gl_edit) return;
    sys_vgui(".x%lx.c delete %sR\n",
        glist_getcanvas(glist), tag);
    glist_eraseiofor(glist, x, tag);
}

    /* change text; if T_OBJECT, remake it.  */
void text_setto(t_text *x, t_glist *glist, const char *buf, int bufsize)
{
    int pos = glist_getindex(glist_getcanvas(glist), &x->te_g);;
    if (x->te_type == T_OBJECT)
    {
        t_binbuf *b = binbuf_new();
        int natom1, natom2, widthwas = x->te_width;
        t_atom *vec1, *vec2;
        binbuf_text(b, buf, bufsize);
        natom1 = binbuf_getnatom(x->te_binbuf);
        vec1 = binbuf_getvec(x->te_binbuf);
        natom2 = binbuf_getnatom(b);
        vec2 = binbuf_getvec(b);
            /* special case: if  pd args change just pass the message on. */
        if (natom1 >= 1 && natom2 >= 1 && vec1[0].a_type == A_SYMBOL
            && !strcmp(vec1[0].a_w.w_symbol->s_name, "pd") &&
             vec2[0].a_type == A_SYMBOL
            && !strcmp(vec2[0].a_w.w_symbol->s_name, "pd"))
        {
            canvas_undo_add(glist_getcanvas(glist), UNDO_RECREATE, "recreate",
                (void *)canvas_undo_set_recreate(glist_getcanvas(glist),
                &x->te_g, pos));

            typedmess(&x->te_pd, gensym("rename"), natom2-1, vec2+1);
            binbuf_free(x->te_binbuf);
            x->te_binbuf = b;
        }
        else  /* normally, just destroy the old one and make a new one. */
        {
            int xwas = x->te_xpix, ywas = x->te_ypix;
            canvas_undo_add(glist_getcanvas(glist), UNDO_RECREATE, "recreate",
                (void *)canvas_undo_set_recreate(glist_getcanvas(glist),
                &x->te_g, pos));
            glist_delete(glist, &x->te_g);
            canvas_objtext(glist, xwas, ywas, widthwas, 0, b);
            canvas_restoreconnections(glist_getcanvas(glist));
                /* if it's an abstraction loadbang it here */
            if (pd_this->pd_newest)
            {
                if (pd_class(pd_this->pd_newest) == canvas_class)
                    canvas_loadbang((t_canvas *)pd_this->pd_newest);
                else if (zgetfn(pd_this->pd_newest, gensym("loadbang")))
                    vmess(pd_this->pd_newest, gensym("loadbang"), "f", LB_LOAD);
            }
        }
            /* if we made a new "pd" or changed a window name,
                update window list */
        if (natom2 >= 1  && vec2[0].a_type == A_SYMBOL
            && !strcmp(vec2[0].a_w.w_symbol->s_name, "pd"))
                canvas_updatewindowlist();
    }
    else
    {
        canvas_undo_add(glist_getcanvas(glist), UNDO_RECREATE, "recreate",
           (void *)canvas_undo_set_recreate(glist_getcanvas(glist),
            &x->te_g, pos));
        binbuf_text(x->te_binbuf, buf, bufsize);

    }
}

    /* this gets called when a message gets sent to an object whose creation
    failed, presumably because of loading a patch with a missing extern or
    abstraction */
static void text_anything(t_text *x, t_symbol *s, int argc, t_atom *argv)
{
}

void g_text_setup(void)
{
    text_class = class_new(gensym("text"), 0, 0, sizeof(t_text),
        CLASS_NOINLET | CLASS_PATCHABLE, 0);
    class_addanything(text_class, text_anything);

    message_class = class_new(gensym("message"), 0, (t_method)message_free,
        sizeof(t_message), CLASS_PATCHABLE, 0);
    class_addbang(message_class, message_bang);
    class_addfloat(message_class, message_float);
    class_addsymbol(message_class, message_symbol);
    class_addlist(message_class, message_list);
    class_addanything(message_class, message_list);

    class_addmethod(message_class, (t_method)message_click, gensym("click"),
        A_FLOAT, A_FLOAT, A_FLOAT, A_FLOAT, A_FLOAT, 0);
    class_addmethod(message_class, (t_method)message_set, gensym("set"),
        A_GIMME, 0);
    class_addmethod(message_class, (t_method)message_add, gensym("add"),
        A_GIMME, 0);
    class_addmethod(message_class, (t_method)message_add2, gensym("add2"),
        A_GIMME, 0);
    class_addmethod(message_class, (t_method)message_addcomma,
        gensym("addcomma"), 0);
    class_addmethod(message_class, (t_method)message_addsemi,
        gensym("addsemi"), 0);
    class_addmethod(message_class, (t_method)message_adddollar,
        gensym("adddollar"), A_FLOAT, 0);
    class_addmethod(message_class, (t_method)message_adddollsym,
        gensym("adddollsym"), A_SYMBOL, 0);

    messresponder_class = class_new(gensym("messresponder"), 0, 0,
        sizeof(t_text), CLASS_PD, 0);
    class_addbang(messresponder_class, messresponder_bang);
    class_addfloat(messresponder_class, (t_method) messresponder_float);
    class_addsymbol(messresponder_class, messresponder_symbol);
    class_addlist(messresponder_class, messresponder_list);
    class_addanything(messresponder_class, messresponder_anything);

    gatom_class = class_new(gensym("gatom"), 0, (t_method)gatom_free,
        sizeof(t_gatom), CLASS_NOINLET | CLASS_PATCHABLE, 0);
    class_addbang(gatom_class, gatom_bang);
    class_addfloat(gatom_class, gatom_float);
    class_addsymbol(gatom_class, gatom_symbol);
    class_addlist(gatom_class, gatom_list);
    class_addmethod(gatom_class, (t_method)gatom_set, gensym("set"),
        A_GIMME, 0);
    class_addmethod(gatom_class, (t_method)gatom_click, gensym("click"),
        A_FLOAT, A_FLOAT, A_FLOAT, A_FLOAT, A_FLOAT, 0);
    class_addmethod(gatom_class, (t_method)gatom_param, gensym("param"),
        A_GIMME, 0);
    class_setwidget(gatom_class, &gatom_widgetbehavior);
    class_setpropertiesfn(gatom_class, gatom_properties);
}
