import FontObserver from 'fontfaceobserver';
import { canUseDOM } from 'fbjs/lib/ExecutionEnvironment';
import { CodedError } from '@unimodules/core';
import { FontDisplay, FontResource } from './Font.types';
import { UnloadFontOptions } from './Font';

function getFontFaceStyleSheet(): CSSStyleSheet | null {
  if (!canUseDOM) {
    return null;
  }
  const styleSheet = getStyleElement();
  return styleSheet.sheet ? (styleSheet.sheet as CSSStyleSheet) : null;
}

type RuleItem = { rule: CSSFontFaceRule; index: number };

function getFontFaceRules(): RuleItem[] {
  const sheet = getFontFaceStyleSheet();
  if (sheet) {
    // @ts-ignore: rule iterator
    const rules = [...sheet.cssRules];

    const items: RuleItem[] = [];

    for (let i = 0; i < rules.length; i++) {
      const rule = rules[i];
      if (rule instanceof CSSFontFaceRule) {
        items.push({ rule, index: i });
      }
    }
    return items;
  }
  return [];
}

function getFontFaceRulesMatchingResource(
  fontFamilyName: string,
  options?: UnloadFontOptions
): RuleItem[] {
  const rules = getFontFaceRules();
  return rules.filter(({ rule }) => {
    return (
      rule.style.fontFamily === fontFamilyName &&
      (options && options.display ? options.display === (rule.style as any).fontDisplay : true)
    );
  });
}

export default {
  get name(): string {
    return 'ExpoFontLoader';
  },

  async unloadAllAsync(): Promise<void> {
    if (!canUseDOM) return;

    const element = document.getElementById(ID);
    if (element && element instanceof HTMLStyleElement) {
      document.removeChild(element);
    }
  },

  async unloadAsync(fontFamilyName: string, options?: UnloadFontOptions): Promise<void> {
    const sheet = getFontFaceStyleSheet();
    if (!sheet) return;
    const items = getFontFaceRulesMatchingResource(fontFamilyName, options);
    for (const item of items) {
      sheet.deleteRule(item.index);
    }
  },

  async loadAsync(fontFamilyName: string, resource: FontResource): Promise<void> {
    if (!canUseDOM) {
      return;
    }

    const canInjectStyle = document.head && typeof document.head.appendChild === 'function';
    if (!canInjectStyle) {
      throw new CodedError(
        'ERR_WEB_ENVIRONMENT',
        `The browser's \`document.head\` element doesn't support injecting fonts.`
      );
    }

    const style = _createWebStyle(fontFamilyName, resource);
    document.head!.appendChild(style);
    // https://github.com/bramstein/fontfaceobserver/issues/109#issuecomment-333356795
    if (navigator.userAgent.includes('Edge')) {
      return;
    }
    return new FontObserver(fontFamilyName).load();
  },
};

const ID = 'expo-generated-fonts';

function getStyleElement(): HTMLStyleElement {
  const element = document.getElementById(ID);
  if (element && element instanceof HTMLStyleElement) {
    return element;
  }
  const styleElement = document.createElement('style');
  styleElement.id = ID;
  styleElement.type = 'text/css';
  return styleElement;
}

function _createWebStyle(fontFamily: string, resource: FontResource): HTMLStyleElement {
  const fontStyle = `@font-face {
    font-family: ${fontFamily};
    src: url(${resource.uri});
    font-display: ${resource.display || FontDisplay.AUTO};
  }`;

  const styleElement = getStyleElement();
  // @ts-ignore: TypeScript does not define HTMLStyleElement::styleSheet. This is just for IE and
  // possibly can be removed if it's unnecessary on IE 11.
  if (styleElement.styleSheet) {
    const styleElementIE = styleElement as any;
    styleElementIE.styleSheet.cssText = styleElementIE.styleSheet.cssText
      ? styleElementIE.styleSheet.cssText + fontStyle
      : fontStyle;
  } else {
    const textNode = document.createTextNode(fontStyle);
    styleElement.appendChild(textNode);
  }
  return styleElement;
}
