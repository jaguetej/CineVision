/**
 * TC-FE-05 — Unit test para frontend/src/pages/DetailPage.jsx
 * Regla de aislamiento del lab: NO se llama al backend real.
 * Se mockean TODOS los servicios usados por la página (MovieService, ActorService,
 * CityService, CommentService, SaloonTimeService) y react-redux.
 *
 * Además se mockean dependencias ESM/CSS que rompen el transformer de Jest
 * por defecto en CRA 5 (Swiper, react-toastify, CSS imports).
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

jest.mock('react-toastify', () => {
  const React = require('react');
  return {
    toast: {
      success: jest.fn(),
      error: jest.fn(),
      warning: jest.fn(),
      info: jest.fn(),
    },
    ToastContainer: () => React.createElement('div', { 'data-testid': 'toast-container-mock' }),
  };
});

// Mocks de servicios (deben ir antes de importar el componente)
jest.mock('../../services/movieService');
jest.mock('../../services/actorService');
jest.mock('../../services/cityService');
jest.mock('../../services/commentService');
jest.mock('../../services/saloonTimeService');

// Mock de react-redux que respeta la firma del selector
jest.mock('react-redux', () => ({
  useSelector: (selectorFn) => selectorFn({ user: { payload: null } }),
  useDispatch: () => jest.fn(),
}));

import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import DetailPage from '../../pages/DetailPage';

import { MovieService } from '../../services/movieService';
import { ActorService } from '../../services/actorService';
import { CityService } from '../../services/cityService';
import { CommentService } from '../../services/commentService';
import { SaloonTimeService } from '../../services/saloonTimeService';

beforeEach(() => {
  MovieService.mockImplementation(() => ({
    getMovieById: () =>
      Promise.resolve({
        data: {
          movieId: 42,
          movieName: 'Detail Page Movie',
          directorName: 'Director Mock',
          description: 'Sinopsis mockeada para test',
          duration: 120,
          categoryName: 'Drama',
          releaseDate: new Date().toISOString(),
          movieImageUrl: '',
          movieTrailerUrl: '',
        },
      }),
    getAllDisplayingMovies: () => Promise.resolve({ data: [] }),
  }));

  ActorService.mockImplementation(() => ({
    getActorsByMovieId: () => Promise.resolve({ data: [{ actorName: 'Actor 1' }] }),
  }));

  CityService.mockImplementation(() => ({
    getCitiesByMovieId: () => Promise.resolve({ data: [] }),
  }));

  CommentService.mockImplementation(() => ({
    getCountOfComments: () => Promise.resolve({ data: 0 }),
    getCommentsByMovieId: () => Promise.resolve({ data: [] }),
  }));

  SaloonTimeService.mockImplementation(() => ({
    getMovieSaloonTimeSaloonAndMovieId: () => Promise.resolve({ data: [] }),
  }));
});

afterEach(() => jest.clearAllMocks());

test('TC-FE-05 — DetailPage renderiza nombre, director y sinopsis tras cargar la película', async () => {
  render(
    <MemoryRouter initialEntries={['/movie/42']}>
      <Routes>
        <Route path="/movie/:movieId" element={<DetailPage />} />
      </Routes>
    </MemoryRouter>
  );

  await waitFor(() => {
    expect(screen.getByText(/Detail Page Movie/i)).toBeInTheDocument();
    expect(screen.getByText(/Director Mock/i)).toBeInTheDocument();
    expect(screen.getByText(/Sinopsis mockeada para test/i)).toBeInTheDocument();
  });
});
