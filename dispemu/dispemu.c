/* CFU Proving Ground since 2025-02    Copyright(c) 2025 Archlab. Science Tokyo /
/ Released under the MIT license https://opensource.org/licenses/mit           */

/******************************************************************************/
/* simple display_emulator ver. 0.0.7 for ST7789       ArchLab, Science Tokyo */
/******************************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <X11/Xutil.h>
#include <cairo/cairo.h>
#include <cairo/cairo-xlib.h>

int size = 2;  /***** typical values are 1, 2, 3 *****/

/******************************************************************************/
void draw_rect(cairo_t *ca, int adr, int c) // cairo_t, adr, color
{
    int x = (adr) & 0xff;
    int y = (adr) >> 8;

    int width = size;
    int r1 = (c >> 11) & 0x3f;
    int g1 = (c >>  5) & 0x3f;
    int b1 = (c >>  0) & 0x1f;

    cairo_set_source_rgb( ca, (float)r1/0x1f, (float)g1/0x1f, (float)b1/0x1f);
    cairo_rectangle( ca, x*size, y*size, width, width );
    cairo_fill( ca );
}

/******************************************************************************/
/* format:@Daaaa_cc    (aaaa: address, cc: color)                             */
/* compress with ex-or                                                        */
/******************************************************************************/
int main(int argc, char** argv)
{
    Display *display;
    XEvent event;
    Window win;
    cairo_surface_t *cs;
    cairo_t *c;

    if(argc==2) size = atoi(argv[1]);
    if(size<=0) size = 2;

    int width = 240*size, height = 240*size;
    display = XOpenDisplay( NULL );
    win = XCreateSimpleWindow( display,
                               RootWindow( display, DefaultScreen(display) ),
                               0, 0, width, height, 0,
                               WhitePixel( display, DefaultScreen(display) ),
                               BlackPixel( display, DefaultScreen(display) ) );
    XMapWindow( display, win );
    XStoreName( display, win, "Simple display emulator");
    XSelectInput( display, win, ExposureMask );
    while( 1 ){
        XNextEvent( display, &event );
        if( event.type == Expose ) break;
    }

    cs = cairo_xlib_surface_create( display, win, DefaultVisual(display,0),
                                    width, height );
    c = cairo_create( cs );

    char str[4096];
    int x_in, y_in, c_in;
    int adr_p = 0; // previous address
    int dat_p = 0; // previous data
    while(1){
        char *p = fgets(str, 4096, stdin);
        if(str[0]=='@' && str[1]=='D'){
            if(str[2]=='f' && str[3]=='i' && str[4]=='n') break;
            sscanf(str, "@D%d_%d\n", &x_in, &c_in);
            int adr = x_in ^ adr_p;
            int dat = c_in ^ dat_p;
            draw_rect( c, adr, dat );
            adr_p = adr;
            dat_p = dat;
            XFlush( display );
        }
    }

    cairo_destroy( c );
    cairo_surface_destroy( cs );
    XDestroyWindow( display, win );
    XCloseDisplay( display );
    return 0;
}
/******************************************************************************/
