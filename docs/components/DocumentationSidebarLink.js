import styled, { keyframes, css } from 'react-emotion';
import NextLink from 'next/link';

import * as React from 'react';
import * as Constants from '~/common/constants';
import stripVersionFromPath from '~/common/stripVersionFromPath';

const STYLES_LINK = css`
  display: block;
  margin-bottom: 10px;
  line-height: 1.3rem;
  text-decoration: none;
`;

const STYLES_ACTIVE = css`
  font-family: ${Constants.fontFamilies.demi};
  color: ${Constants.colors.expoLighter};

  :visited {
    color: ${Constants.colors.expo};
  }

  :hover {
    color: ${Constants.colors.expo};
  }
`;

const STYLES_DEFAULT = css`
  font-family: ${Constants.fontFamilies.book};
  color: ${Constants.colors.black80};
  transition: 200ms ease color;

  :visited {
    color: ${Constants.colors.black60};
  }

  :hover {
    color: ${Constants.colors.expo};
  }
`;

export default class DocumentationSidebarLink extends React.Component {
  componentDidMount() {
    // Consistent link behavior across dev server and static export
    global.__NEXT_DATA__.nextExport = true;
  }

  isSelected() {
    if (!this.props.url) {
      return false;
    }

    // Special case for root url
    if (this.props.info.name === 'What is Expo?') {
      const asPath = this.props.asPath;
      if (this.props.asPath.match(/\/versions\/[\w\.]+\/$/)) {
        return true;
      }
    }

    const linkUrl = stripVersionFromPath(this.props.info.as || this.props.info.href);
    if (
      linkUrl === stripVersionFromPath(this.props.url.pathname) ||
      linkUrl === stripVersionFromPath(this.props.asPath)
    ) {
      return true;
    }

    return false;
  }

  render() {
    const customDataAttributes = this.isSelected()
      ? {
          'data-sidebar-anchor-selected': true,
        }
      : {};

    return (
      <NextLink href={this.props.info.href} as={this.props.info.as || this.props.info.href}>
        <a
          {...customDataAttributes}
          className={`${STYLES_LINK} ${this.isSelected() ? STYLES_ACTIVE : STYLES_DEFAULT}`}>
          {this.props.children}
        </a>
      </NextLink>
    );
  }
}
