import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import {useActiveVersion} from '@docusaurus/plugin-content-docs/client';
import styles from './styles.module.css';

// Links stay inside the version the reader is browsing (stable or develop).
function useVersionPath(path) {
  const version = useActiveVersion();
  const base = (version?.path ?? '').replace(/\/$/, '');
  return `${base}/${path}`;
}

function VersionLink({to, ...props}) {
  return <Link to={useVersionPath(to)} {...props} />;
}

export function Hero() {
  return (
    <header className={styles.hero}>
      <img className={styles.logo} src={useBaseUrl('/assets/proveasio-logo.png')} alt="Proveasio" />
      <p className={styles.tagline}>
        One Ansible run turns a fresh Ubuntu or WSL2 machine into a terminal-first
        workstation for development and operations.
      </p>
      <div className={styles.buttons}>
        <VersionLink className="button button--primary button--lg" to="main/installation">
          Install on Ubuntu / WSL2
        </VersionLink>
        <VersionLink className="button button--secondary button--lg" to="main/docker/build">
          Use the Docker image
        </VersionLink>
      </div>
    </header>
  );
}

const FEATURES = [
  {title: 'Shell', icon: '>_', to: 'main/features/terminal',
    text: 'zsh with oh-my-zsh and powerlevel10k, fzf everywhere, zoxide, eza, bat and pay-respects.'},
  {title: 'tmux', icon: '[|]', to: 'usage/tmux',
    text: 'Splits shared with Neovim, saved sessions, buffer search and text extraction.'},
  {title: 'Git', icon: '±', to: 'main/features/git',
    text: 'lazygit with AI commit messages, diff-so-fancy, git-fuzzy and gita.'},
  {title: 'Kubernetes & IaC', icon: 'k8s', to: 'usage/kubernetes',
    text: 'kubectl, k9s, kind, Helm, Argo CD, Terraform, OpenTofu, Azure and AWS CLIs.'},
  {title: 'Neovim', icon: 'nv', to: 'usage/vim',
    text: 'An AstroNvim-based IDE with language servers, Git tools and AI assistants.'},
  {title: 'AI agents', icon: 'AI', to: 'usage/ai',
    text: 'opencode, ccmux to track agents in tmux, and AI commits in lazygit.'},
  {title: 'Languages', icon: '{ }', to: 'main/features/languages',
    text: 'Version managers for Python, Node, Go, Ruby, Java and Rust.'},
  {title: 'Docker image', icon: 'ctr', to: 'main/docker/build',
    text: 'The same setup as a container, a devcontainer or a slim image.'},
];

function FeatureCard({title, icon, text, to}) {
  return (
    <VersionLink to={to} className={clsx('card', styles.card)}>
      <span className={styles.icon} aria-hidden="true">{icon}</span>
      <h3 className={styles.cardTitle}>{title}</h3>
      <p className={styles.cardText}>{text}</p>
    </VersionLink>
  );
}

export function FeatureGrid() {
  return (
    <section className={styles.grid}>
      {FEATURES.map((f) => (
        <FeatureCard key={f.title} {...f} />
      ))}
    </section>
  );
}
