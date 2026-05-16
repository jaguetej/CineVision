/**
 * TC-FE-04 — Unit test para frontend/src/pages/MainPage.jsx
 * Regla de aislamiento del lab: NO se llama al backend real.
 * Se mockea la clase MovieService para retornar películas deterministas.
 *
 * Además se mockean dependencias ESM/CSS que rompen el transformer de Jest
 * por defecto en CRA 5 (Swiper y los imports de CSS).
 */

// ─── Mocks de módulos problemáticos (deben declararse ANTES de cualquier import) ───
jest.mock('swiper/react', () => {
  const React = require('react');
  return {
    Swiper: ({ children }) => React.createElement('div', { 'data-testid': 'swiper-mock' }, children),
    SwiperSlide: ({ children }) => React.createElement('div', { 'data-testid': 'swiper-slide-mock' }, children),
  };
});
jest.mock('swiper', () => ({ Pagination: 'PaginationMock' }));
jest.mock('swiper/css', () => ({}), { virtual: true });
jest.mock('swiper/css/pagination', () => ({}), { virtual: true });

// Mock del módulo MovieService antes de importar el componente
jest.mock('../../services/movieService');

import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import MainPage from '../../pages/MainPage';
import { MovieService } from '../../services/movieService';

beforeEach(() => {
  MovieService.mockImplementation(() => ({
    getAllDisplayingMovies: () =>
      Promise.resolve({
        data: [
          { movieId: 1, movieName: 'Mocked Displaying One', movieImageUrl: '' },
          { movieId: 2, movieName: 'Mocked Displaying Two', movieImageUrl: '' },
        ],
      }),
    getAllComingSoonMovies: () =>
      Promise.resolve({
        data: [{ movieId: 3, movieName: 'Mocked Coming Soon', movieImageUrl: '' }],
      }),
  }));
});

afterEach(() => {
  jest.clearAllMocks();
});

test('TC-FE-04 — MainPage renderiza los nombres de películas en cartelera tras el useEffect', async () => {
  render(
    <MemoryRouter>
      <MainPage />
    </MemoryRouter>
  );

  // El h1 "CineVision" debe estar siempre presente. Se usa getByRole para evitar
  // ambigüedad con el h2 que también contiene la palabra "CineVision".
  expect(screen.getByRole('heading', { name: 'CineVision' })).toBeInTheDocument();

  // Los nombres mockeados aparecen cuando el efecto resuelve la promesa.
  await waitFor(() => {
    expect(screen.getByText(/Mocked Displaying One/i)).toBeInTheDocument();
    expect(screen.getByText(/Mocked Displaying Two/i)).toBeInTheDocument();
  });
});
