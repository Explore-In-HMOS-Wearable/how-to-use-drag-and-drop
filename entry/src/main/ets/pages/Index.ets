import { dragController, curves, UIContext } from '@kit.ArkUI';
import { unifiedDataChannel } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import type { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  @State private dropText: string = 'Drop here';
  @State private dragLabel: string = 'Hello from drag!';
  @State private isDragging: boolean = false;
  @State private dropScale: number = 1.0;
  @State private dropBorder: ResourceColor = '#111827';

  private readonly watchSize: string = '100%';

  @Builder DragPreviewBuilder() {
    Column() {
      Text('📦')
        .fontSize(22)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 4 })
      Text(this.dragLabel)
        .fontColor(Color.White)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .lineHeight(20)
    }
    .width(150)
    .height(90)
    .borderRadius(16)
    .backgroundColor('#2563EB')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 10, right: 10 })
    .shadow({ radius: 16, color: '#33000000', offsetX: 0, offsetY: 2 })
  }

  private startDrag(pointerId: number = 0): void {
    const txt = new unifiedDataChannel.PlainText();
    txt.textContent = this.dragLabel;
    txt.abstract = 'demo';
    const unified = new unifiedDataChannel.UnifiedData(txt);

    const info: dragController.DragInfo = {
      pointerId,
      data: unified,
      extraParams: ''
    };

    this.isDragging = true;
    try {
      this.getUIContext()
        .getDragController()
        .executeDrag(
          () => { this.DragPreviewBuilder(); },
          info,
          (err: BusinessError | undefined, res) => {
            this.isDragging = false;
            if (err) {
              hilog.error(0x0000, 'drag', `executeDrag error: ${err.message}`);
              return;
            }
            if (res && res.event) {
              const ok = res.event.getResult() === DragResult.DRAG_SUCCESSFUL;
              hilog.info(0x0000, 'drag', ok ? 'SUCCESS' : 'FAILED');
            }
          }
        );
    } catch (e) {
      this.isDragging = false;
      hilog.error(0x0000, 'drag', `executeDrag threw: ${String(e)}`);
    }
  }

  build() {
    Stack() {
      Column() {}
      .width(this.watchSize)
      .height(this.watchSize)
      .clip(Circle({ width: '100%', height: '100%' }))
      .backgroundColor('#0B1220')

      Column() {
        Button('Drag')
          .type(ButtonType.Capsule)
          .fontSize(12)
          .height(36)
          .margin({ top: 8, bottom: 8 })
          .backgroundColor('#2563EB')
          .fontColor(Color.White)
          .opacity(this.isDragging ? 0.9 : 1)
          .shadow({ radius: 12, color: '#26000000', offsetX: 0, offsetY: 2 })
          .onClick(() => {
            this.dragLabel = 'Hello from drag!';
          })
          .onTouch((ev?: TouchEvent) => {
            if (!ev) return;
            if (ev.type === TouchType.Down) {
              this.startDrag(0);
            }
          })

        Column() {
          Text(this.dropText)
            .fontSize(14)
            .textAlign(TextAlign.Center)
            .fontColor(Color.White)
            .width('100%')
            .maxLines(2)
            .lineHeight(18)
            .padding({ left: 6, right: 6 })
        }
        .width(180)
        .height(92)
        .borderRadius(20)
        .backgroundColor('#111827')
        .border({ color: this.dropBorder, width: 1 })
        .scale({ x: this.dropScale, y: this.dropScale })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onDragEnter(() => {
          this.dropScale = 1.05;
          this.dropBorder = '#22C55E';
          try {
            const ui: UIContext = this.getUIContext();
            const preview = ui.getDragController().getDragPreview();
            const anim: dragController.AnimationOptions = {
              duration: 250,
              curve: curves.cubicBezierCurve(0.2, 0, 0, 1)
            };
            preview.animate(anim, () => {
              preview.setForegroundColor(Color.Green);
            });
          } catch (err) {
            const e = err as BusinessError;
            hilog.error(0x0000, 'preview', `animate error: ${e?.code} ${e?.message}`);
          }
        })
        .onDragLeave(() => {
          this.dropScale = 1.0;
          this.dropBorder = '#111827';
        })
        .onDrop((dragEvent?: DragEvent) => {
          this.dropScale = 1.0;
          this.dropBorder = '#111827';
          if (!dragEvent) return;
          const records = dragEvent.getData().getRecords();
          if (records.length > 0) {
            const first = records[0] as unifiedDataChannel.PlainText;
            this.dropText = first.textContent ?? 'dropped';
          }
        })

        Text('Tip: Press “Drag”, move the 📦 preview, and drop it into the box.')
          .fontSize(10)
          .fontColor('#94A3B8')
          .margin({ top: 8 })
          .opacity(0.9)
      }
      .width('70%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding(8)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Center)
  }
}
