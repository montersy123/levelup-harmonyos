/** 纯函数小工具。 */

/** 千分位分组：1480 → "1,480"（对应设计稿里的 1,480 / 2,000 写法）。 */
export function grouped(value: number): string {
  const raw: string = Math.round(value).toString();
  let out: string = '';
  let count: number = 0;
  for (let i = raw.length - 1; i >= 0; i--) {
    out = raw.charAt(i) + out;
    count += 1;
    if (count % 3 === 0 && i > 0) {
      out = ',' + out;
    }
  }
  return out;
}

/** 百分比字符串，保留整数。 */
export function percent(value: number): string {
  return Math.round(value).toString() + '%';
}
