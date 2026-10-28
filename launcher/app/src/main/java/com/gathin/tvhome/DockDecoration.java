package com.gathin.tvhome;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.graphics.RectF;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

/**
 * Draws a frosted-glass panel behind the first (dock) row and adds a gap below it. The "frost" is a tiny,
 * pre-blurred copy of the current wallpaper stretched back to screen size and clipped to the panel, so it
 * works on Android 11 (no RenderEffect) and costs one small bitmap.
 */
public class DockDecoration extends RecyclerView.ItemDecoration {

    private final int dockSize;
    private final float density;
    private final Paint frost = new Paint(Paint.FILTER_BITMAP_FLAG);
    private final Paint tint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint edge = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final RectF rect = new RectF();
    private final RectF screen = new RectF();
    private final Path clip = new Path();
    private Bitmap blurred;

    DockDecoration(int dockSize, float density) {
        this.dockSize = dockSize;
        this.density = density;
        tint.setColor(0x33FFFFFF);
        edge.setStyle(Paint.Style.STROKE);
        edge.setStrokeWidth(density);
        edge.setColor(0x4DFFFFFF);
    }

    /**
     * @param blurred tiny blurred wallpaper, or null for a plain translucent panel
     * @param screen  where the full-size wallpaper sits, in the RecyclerView's coordinates
     */
    void setBackdrop(Bitmap blurred, RectF screen) {
        this.blurred = blurred;
        this.screen.set(screen);
    }

    @Override
    public void getItemOffsets(@NonNull Rect outRect, @NonNull View view, @NonNull RecyclerView parent,
                               @NonNull RecyclerView.State state) {
        int pos = parent.getChildAdapterPosition(view);
        if (pos >= 0 && pos < dockSize) {
            outRect.top = (int) (6 * density);
            outRect.bottom = (int) (12 * density);
        }
    }

    @Override
    public void onDraw(@NonNull Canvas c, @NonNull RecyclerView parent, @NonNull RecyclerView.State state) {
        boolean any = false;
        for (int i = 0; i < parent.getChildCount(); i++) {
            View child = parent.getChildAt(i);
            int pos = parent.getChildAdapterPosition(child);
            if (pos < 0 || pos >= dockSize) continue;
            View card = child.findViewById(R.id.card);
            if (card == null) continue;
            float l = child.getLeft() + card.getLeft();
            float t = child.getTop() + card.getTop() + child.getTranslationY();
            float r = l + card.getWidth();
            float b = t + card.getHeight();
            if (!any) {
                rect.set(l, t, r, b);
                any = true;
            } else {
                rect.union(l, t, r, b);
            }
        }
        if (!any) return;
        float pad = 14 * density;
        rect.inset(-pad, -pad);
        float radius = 26 * density;

        if (blurred != null) {
            clip.reset();
            clip.addRoundRect(rect, radius, radius, Path.Direction.CW);
            c.save();
            c.clipPath(clip);
            c.drawBitmap(blurred, null, screen, frost);
            c.restore();
        }
        c.drawRoundRect(rect, radius, radius, tint);
        c.drawRoundRect(rect, radius, radius, edge);
    }
}
