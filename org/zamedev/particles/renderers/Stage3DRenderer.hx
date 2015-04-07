package org.zamedev.particles.renderers;

#if (flash11 && zameparticles_stage3d)

import com.asliceofcrazypie.flash.TilesheetStage3D;
import openfl.display.Sprite;
import openfl.display.Tilesheet;
import openfl.display3D.Context3DRenderMode;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.gl.GL;

typedef Stage3DRendererData = {
    ps:ParticleSystem,
    tilesheet:TilesheetStage3D,
    tileData:Array<Float>,
    updated:Bool,
};

/**
 * Stage3DRenderer
 * dependency https://github.com/as3boyan/TilesheetStage3D
 * @usage Call TilesheetStage3D.init(stage, 0, 5, onInit, Context3DRenderMode.AUTO); before DefaultParticleRenderer.createInstance(); (put this inside onInit function)
 * @author loudo
 */
class Stage3DRenderer extends Sprite implements ParticleSystemRenderer {
    private static inline var TILE_DATA_FIELDS = 9; // x, y, tileId, scale, rotation, red, green, blue, alpha

    private var dataList:Array<Stage3DRendererData> = [];

    public function new() {
        super();
        mouseEnabled = false;
    }

    public function addParticleSystem(ps:ParticleSystem):Void {
        if (dataList.length == 0) {
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }

        ps.__initialize();

        var tilesheet = new TilesheetStage3D(TilesheetStage3D.fixTextureSize(ps.textureBitmapData));

        tilesheet.addTileRect(
            ps.textureBitmapData.rect.clone(),
            new Point(ps.textureBitmapData.rect.width / 2, ps.textureBitmapData.rect.height / 2)
        );

        var tileData = new Array<Float>();
        tileData[Std.int(ps.maxParticles * TILE_DATA_FIELDS - 1)] = 0.0;

        dataList.push({
            ps: ps,
            tilesheet: tilesheet,
            tileData: tileData,
            updated: false,
        });
    }

    public function removeParticleSystem(ps:ParticleSystem):Void {
        var index = 0;

        while (index < dataList.length) {
            if (dataList[index].ps == ps) {
                dataList.splice(index, 1);
            } else {
                index++;
            }
        }

        if (dataList.length == 0) {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
    }

    private function onEnterFrame(_):Void {
        var updated = false;

        for (data in dataList) {
            if (data.updated = data.ps.__update()) {
                updated = true;
            }
        }

        if (!updated) {
            return;
        }

        TilesheetStage3D.clearGraphic(graphics);
        graphics.clear();

        for (data in dataList) {
            if (!data.updated) {
                continue;
            }

            var ps = data.ps;
            var tileData = data.tileData;
            var index:Int = 0;
            var ethalonSize:Float = ps.textureBitmapData.width;

            var flags = (ps.blendFuncSource == GL.SRC_ALPHA && ps.blendFuncDestination == GL.ONE
                ? Tilesheet.TILE_BLEND_ADD
                : Tilesheet.TILE_BLEND_NORMAL
            );

            for (i in 0 ... ps.__particleCount) {
                var particle = ps.__particleList[i];

                tileData[index] = particle.position.x * ps.particleScaleX; // x
                tileData[index + 1] = particle.position.y * ps.particleScaleY; // y
                tileData[index + 2] = 0.0; // tileId
                tileData[index + 3] = particle.particleSize / ethalonSize * ps.particleScaleSize; // scale
                tileData[index + 4] = particle.rotation; // rotation
                tileData[index + 5] = particle.color.r;
                tileData[index + 6] = particle.color.g;
                tileData[index + 7] = particle.color.b;
                tileData[index + 8] = particle.color.a;

                index += TILE_DATA_FIELDS;
            }

            if (index == 0) {
                tileData[index] = 0.0; // x
                tileData[index + 1] = 0.0; // y
                tileData[index + 2] = 0.0; // tileId
                tileData[index + 3] = 1.0; // scale
                tileData[index + 4] = 0.0; // rotation
                tileData[index + 5] = 0.0;
                tileData[index + 6] = 0.0;
                tileData[index + 7] = 0.0;
                tileData[index + 8] = 0.0;

                index += TILE_DATA_FIELDS;
            }

            data.tilesheet.drawTiles(
                graphics,
                tileData,
                true,
                Tilesheet.TILE_SCALE | Tilesheet.TILE_ROTATION | Tilesheet.TILE_RGB | Tilesheet.TILE_ALPHA | flags,
                index
            );
        }
    }
}

#end
