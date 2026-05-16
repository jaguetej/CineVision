package com.kaankaplan.movieService.business;

import com.kaankaplan.movieService.business.abstracts.CategoryService;
import com.kaankaplan.movieService.business.abstracts.DirectorService;
import com.kaankaplan.movieService.business.concretes.MovieServiceImpl;
import com.kaankaplan.movieService.dao.MovieDao;
import com.kaankaplan.movieService.entity.dto.MovieResponseDto;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.web.reactive.function.client.WebClient;

import java.util.Collections;
import java.util.Date;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * Tests unitarios para MovieServiceImpl.
 * Regla de aislamiento del lab: NO se conecta a PostgreSQL real.
 * Toda la capa DAO se sustituye por un mock de Mockito.
 */
@ExtendWith(MockitoExtension.class)
class MovieServiceImplTest {

    @Mock
    private MovieDao movieDao;

    @Mock
    private CategoryService categoryService;

    @Mock
    private DirectorService directorService;

    @Mock
    private WebClient.Builder webClientBuilder;

    @InjectMocks
    private MovieServiceImpl movieService;

    private MovieResponseDto sampleDto(int id, String name) {
        return new MovieResponseDto(
                id, name, "desc", 100, new Date(), true,
                1, "Drama", "http://img/" + id + ".png",
                "http://trailer/" + id, "Director " + id
        );
    }

    @Test
    @DisplayName("TC-BE-01 — getAllDisplayingMoviesInVision delega en MovieDao y retorna la lista")
    void getAllDisplayingMoviesInVision_returnsDaoResult() {
        List<MovieResponseDto> expected = List.of(sampleDto(1, "Movie A"), sampleDto(2, "Movie B"));
        when(movieDao.getAllDisplayingMoviesInVision()).thenReturn(expected);

        List<MovieResponseDto> actual = movieService.getAllDisplayingMoviesInVision();

        assertThat(actual).isEqualTo(expected);
        verify(movieDao, times(1)).getAllDisplayingMoviesInVision();
    }

    @Test
    @DisplayName("TC-BE-02 — getAllComingSoonMovies delega en MovieDao y retorna la lista")
    void getAllComingSoonMovies_returnsDaoResult() {
        List<MovieResponseDto> expected = List.of(sampleDto(3, "Coming X"));
        when(movieDao.getAllComingSoonMovies()).thenReturn(expected);

        List<MovieResponseDto> actual = movieService.getAllComingSoonMovies();

        assertThat(actual).isEqualTo(expected);
        verify(movieDao).getAllComingSoonMovies();
    }

    @Test
    @DisplayName("TC-BE-03 — getMovieByMovieId(id) retorna el DTO devuelto por el DAO")
    void getMovieByMovieId_returnsDto() {
        MovieResponseDto expected = sampleDto(7, "Detail Movie");
        when(movieDao.getMovieById(7)).thenReturn(expected);

        MovieResponseDto actual = movieService.getMovieByMovieId(7);

        assertThat(actual).isNotNull();
        assertThat(actual.getMovieId()).isEqualTo(7);
        assertThat(actual.getMovieName()).isEqualTo("Detail Movie");
        verify(movieDao).getMovieById(7);
    }

    @Test
    @DisplayName("TC-BE-04 — getMovieByMovieId propaga null cuando el DAO no encuentra la película")
    void getMovieByMovieId_returnsNullWhenDaoReturnsNull() {
        when(movieDao.getMovieById(anyInt())).thenReturn(null);

        MovieResponseDto actual = movieService.getMovieByMovieId(99);

        assertThat(actual).isNull();
        // Lista vacía también es un escenario sano para coming-soon:
        when(movieDao.getAllComingSoonMovies()).thenReturn(Collections.emptyList());
        assertThat(movieService.getAllComingSoonMovies()).isEmpty();
    }
}
