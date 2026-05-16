/**
 * TC-FE-01 / TC-FE-02 — Unit tests para frontend/src/services/movieService.js
 * Regla de aislamiento del lab: NO se llama al backend real.
 * axios se reemplaza por un mock de Jest.
 */
import axios from 'axios';
import { MovieService } from '../../services/movieService';

jest.mock('axios');

describe('MovieService (capa de consumo de API)', () => {
  const service = new MovieService();
  const baseUrl = service.apiUrl;

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('TC-FE-01 — getAllDisplayingMovies hace GET al endpoint correcto y resuelve con los datos', async () => {
    const fake = { data: [{ movieId: 1, movieName: 'Mocked A' }] };
    axios.get.mockResolvedValueOnce(fake);

    const result = await service.getAllDisplayingMovies();

    expect(axios.get).toHaveBeenCalledTimes(1);
    expect(axios.get).toHaveBeenCalledWith(baseUrl + 'displayingMovies');
    expect(result.data[0].movieName).toBe('Mocked A');
  });

  test('TC-FE-02 — getMovieById concatena el id en la URL y devuelve el DTO mockeado', async () => {
    const fake = { data: { movieId: 42, movieName: 'Detail Mocked', directorName: 'Dir Z' } };
    axios.get.mockResolvedValueOnce(fake);

    const result = await service.getMovieById(42);

    expect(axios.get).toHaveBeenCalledWith(baseUrl + 42);
    expect(result.data.movieId).toBe(42);
    expect(result.data.directorName).toBe('Dir Z');
  });

  test('TC-FE-03 — getAllComingSoonMovies usa el endpoint comingSoonMovies', async () => {
    axios.get.mockResolvedValueOnce({ data: [] });
    await service.getAllComingSoonMovies();
    expect(axios.get).toHaveBeenCalledWith(baseUrl + 'comingSoonMovies');
  });
});
