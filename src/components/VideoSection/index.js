import React from 'react';
import styles from './styles.module.css';

export default function VideoSection() {
  return (
    <section className={styles.videoSection}>
      <div className="container">
        <div className={styles.videoWrapper}>
          <h2 className={styles.videoTitle}>See Celte in Action</h2>
          <p className={styles.videoDescription}>
            Watch how Celte dynamically manages server resources and ensures a smooth gaming experience.
            Our demonstration shows the server meshing system in action with real-world scenarios.
          </p>
          <div className={styles.videoContainer}>
            {/* Replace with your demonstration video URL */}
            <iframe
              className={styles.video}
              src="https://www.youtube.com/embed/your-video-id"
              title="Celte System Demonstration"
              frameBorder="0"
              allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
              allowFullScreen
            />
          </div>
          <div className={styles.techHighlights}>
            <div className={styles.techItem}>
              <h3>Dynamic Scaling</h3>
              <p>Automatic resource adaptation based on server load</p>
            </div>
            <div className={styles.techItem}>
              <h3>Optimized Performance</h3>
              <p>Reduced latency and efficient resource utilization</p>
            </div>
            <div className={styles.techItem}>
              <h3>Easy Integration</h3>
              <p>Simple integration with your existing infrastructure</p>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}