import { Quest } from '../model/Quest';
import { QUEST_CATALOG } from '../data/Data';
import { QuestCard } from '../view/QuestCard';
import { Layout, Space } from '../common/Theme';

/** 任务卡网格：随宽度在 2 / 3 / 4 列之间自适应（平板、折叠屏展开）。 */
export const GRID_GAP: number = 10;

export function columnsFor(viewport: number): number {
  const w: number = viewport < Layout.contentMax ? viewport : Layout.contentMax;
  if (w >= Layout.grid4) {
    return 4;
  }
  if (w >= Layout.grid3) {
    return 3;
  }
  return 2;
}

@Component
export struct QuestGrid {
  @Prop viewport: number;
  onOpen: (quest: Quest) => void = () => {};

  build() {
    Column({ space: GRID_GAP }) {
      ForEach(this.rows(), (row: Quest[], rowIndex: number) => {
        Row({ space: GRID_GAP }) {
          ForEach(row, (quest: Quest) => {
            QuestCard({
              quest: quest,
              cardWidth: this.cardWidth(),
              onOpen: (q: Quest) => {
                this.onOpen(q);
              }
            })
          }, (quest: Quest) => quest.id)
        }
        .width('100%')
      }, (row: Quest[], rowIndex: number) => 'row-' + rowIndex.toString())
    }
    .width('100%')
    .padding({ left: Space.x14, right: Space.x14 })
  }

  private columns(): number {
    return columnsFor(this.viewport);
  }

  private cardWidth(): number {
    const contentW: number = this.viewport < Layout.contentMax ? this.viewport : Layout.contentMax;
    const usable: number = contentW - Space.x14 * 2;
    const cols: number = this.columns();
    return Math.floor((usable - GRID_GAP * (cols - 1)) / cols);
  }

  private rows(): Quest[][] {
    const perRow: number = this.columns();
    const out: Quest[][] = [];
    let current: Quest[] = [];
    for (const q of QUEST_CATALOG) {
      current.push(q);
      if (current.length === perRow) {
        out.push(current);
        current = [];
      }
    }
    if (current.length > 0) {
      out.push(current);
    }
    return out;
  }
}
