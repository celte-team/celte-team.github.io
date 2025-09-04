import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';
import VideoSection from '@site/src/components/VideoSection';

import Heading from '@theme/Heading';
import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">An innovative server meshing solution for video games</p>
        <p className={styles.heroDescription}>
          Celte revolutionizes game server architecture by enabling dynamic and efficient resource management.
          Our server meshing solution provides automatic scaling and smooth gaming experience for all players.
        </p>
        <div className={styles.buttons}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/intro">
            Discover Celte
          </Link>
          <Link
            className="button button--outline button--secondary button--lg"
            href="https://github.com/celte-team"
            target="_blank"
            rel="noopener noreferrer">
            View on GitHub
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title} - Server Meshing Solution`}
      description="Celte - An innovative server meshing solution for video games, enabling dynamic and efficient server resource scaling">
      <HomepageHeader />
      <main>
        <VideoSection />
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
