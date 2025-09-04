import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

const FeatureList = [
  {
    title: 'Server Meshing Solution',
    description: (
      <>
        Server meshing is today the most efficient solution to handle a large number of players in a single game world.
      </>
    ),
  },
  {
    title: 'Implementable in your Project',
    description: (
      <>
        Celte is a server meshing solution under the form of an SDK, implementable in any custom game engine.
      </>
    ),
  },
  {
    title: 'Scalable',
    description: (
      <>
        Celte is designed to be scalable and can adapt to the growth of your project.
      </>
    ),
  },
];

function Feature({title, description}) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="text--center padding-horiz--md">
          <Heading as="h3" className={clsx('margin-bottom--lg margin-top--lg', styles.featureCard)}>
            What is Celte?
          </Heading>
          <p>
            Celte is a server meshing solution under the form of an SDK. It is already implemented in <a href="https://godotengine.org" target="_blank" rel="noopener noreferrer">Godot Engine</a>. And can be integrated in any custom game engine.
          </p>
        </div>
        <div className={clsx('margin-bottom--lg margin-top--lg row', styles.featureCard)}>
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
