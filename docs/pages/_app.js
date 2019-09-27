import React from 'react'
import * as Sentry from '@sentry/browser';
import App, { Container } from 'next/app'

Sentry.init({dsn: "https://67e35a01698649d5aa33aaab61777851@sentry.io/1526800"});

class MyApp extends App {
  render() {
    const { Component, pageProps } = this.props

    return (
      <Container>
        <Component {...pageProps} />
      </Container>
    )
  }
}

export default MyApp