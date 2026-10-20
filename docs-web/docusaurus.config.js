// @ts-check
// `@type` JSDoc annotations allow editor autocompletion and type checking
// (when paired with `@ts-check`).
// There are various equivalent ways to declare your Docusaurus config.
// See: https://docusaurus.io/docs/api/docusaurus-config

import {themes as prismThemes} from 'prism-react-renderer';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'Proveasio',
  tagline: 'Provision your environment with ease',
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'https://ziwi01.github.io',
  baseUrl: '/proveasio/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'ziwi01', // Usually your GitHub org/user name.
  projectName: 'proveasio', // Usually your repo name.

  onBrokenLinks: 'throw',

  future: {
    v4: {
      removeLegacyPostBuildHeadAttribute: true,
    },
    faster: true,
  },

  markdown: {
    hooks: {
      onBrokenMarkdownLinks: 'warn',
    },
  },

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  clientModules: ['./src/fonts.js'],

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          sidebarPath: './sidebars.js',
          routeBasePath: '/',
          editUrl: 'https://github.com/Ziwi01/proveasio/edit/develop/docs-web/',
          // versioned_docs are regenerated at release time; edit the current docs instead
          editCurrentVersion: true,
          showLastUpdateTime: true,
          versions: {
            current: {
              label: 'develop',
            },
          },
        },
        theme: {
          customCss: './src/css/custom.css',
        },
        blog: false
      }),
    ],
  ],

  themes: [
    [
      require.resolve("@easyops-cn/docusaurus-search-local"),
      /** @type {import("@easyops-cn/docusaurus-search-local").PluginOptions} */
      ({
        hashed: true,
        indexBlog: false,
        docsRouteBasePath: '/',
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      image: 'assets/proveasio-logo.png',
      metadata: [
        {name: 'keywords', content: 'ansible, ubuntu, wsl2, dotfiles, zsh, tmux, neovim, devops, docker'},
      ],
      docs: {
        sidebar: {
          hideable: true,
          autoCollapseCategories: true,
        },
      },
      navbar: {
        title: 'Proveasio',
        hideOnScroll: true,
        logo: {
          alt: 'Proveasio logo',
          src: 'img/logo.png',
        },
        items: [
          {
            type: 'docSidebar',
            sidebarId: 'mainSidebar',
            position: 'left',
            label: 'Docs',
          },
          {
            type: 'docSidebar',
            sidebarId: 'usageSidebar',
            position: 'left',
            label: 'Usage',
          },
          {
            type: 'docsVersionDropdown',
            position: 'right',
            dropdownActiveClassDisabled: true,
          },
          {
            href: 'https://github.com/Ziwi01/proveasio',
            position: 'right',
            className: 'header-github-link',
            'aria-label': 'GitHub repository',
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Docs',
            items: [
              {label: 'Requirements', to: '/main/requirements'},
              {label: 'Installation', to: '/main/installation'},
              {label: 'Docker image', to: '/main/docker/build'},
              {label: 'Troubleshooting', to: '/main/troubleshooting'},
            ],
          },
          {
            title: 'Usage',
            items: [
              {label: 'Terminal', to: '/usage/terminal'},
              {label: 'Tmux', to: '/usage/tmux'},
              {label: 'Neovim', to: '/usage/vim'},
            ],
          },
          {
            title: 'Project',
            items: [
              {label: 'GitHub', href: 'https://github.com/Ziwi01/proveasio'},
              {label: 'Releases', href: 'https://github.com/Ziwi01/proveasio/releases'},
              {label: 'Issues', href: 'https://github.com/Ziwi01/proveasio/issues'},
            ],
          },
        ],
        copyright: `Copyright © ${new Date().getFullYear()} Ziwi. Built with Docusaurus.`,
      },
      prism: {
        theme: prismThemes.oneLight,
        darkTheme: prismThemes.oneDark,
        additionalLanguages: ['bash', 'hcl', 'lua', 'powershell', 'toml', 'ini', 'docker'],
      },
      colorMode: {
        defaultMode: 'dark',
        disableSwitch: false,
        respectPrefersColorScheme: false,
      },
    }),
};

export default config;
