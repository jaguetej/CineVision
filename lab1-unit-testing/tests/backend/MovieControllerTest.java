package com.kaankaplan.movieService.controller;

import com.kaankaplan.movieService.business.abstracts.MovieService;
import com.kaankaplan.movieService.entity.dto.MovieResponseDto;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Date;
import java.util.List;

import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Tests unitarios del MovieController.
 * Regla de aislamiento del lab: NO se ejecuta el contexto completo de Spring ni se golpea BD.
 * @WebMvcTest carga solo la capa MVC y MovieService se sustituye con @MockBean.
 */
@WebMvcTest(MovieController.class)
class MovieControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private MovieService movieService;

    private MovieResponseDto dto(int id, String name) {
        return new MovieResponseDto(
                id, name, "desc", 100, new Date(), true,
                1, "Drama", "http://img/" + id + ".png",
                "http://trailer/" + id, "Director " + id
        );
    }

    @Test
    @DisplayName("TC-BE-05 — GET /api/movie/movies/displayingMovies → 200 + array JSON")
    void getDisplayingMovies() throws Exception {
        when(movieService.getAllDisplayingMoviesInVision())
                .thenReturn(List.of(dto(1, "Movie A"), dto(2, "Movie B")));

        mockMvc.perform(get("/api/movie/movies/displayingMovies"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].movieName").value("Movie A"))
                .andExpect(jsonPath("$[1].movieId").value(2));
    }

    @Test
    @DisplayName("TC-BE-06 — GET /api/movie/movies/comingSoonMovies → 200 + array JSON")
    void getComingSoonMovies() throws Exception {
        when(movieService.getAllComingSoonMovies())
                .thenReturn(List.of(dto(3, "Coming X")));

        mockMvc.perform(get("/api/movie/movies/comingSoonMovies"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].movieName").value("Coming X"));
    }

    @Test
    @DisplayName("TC-BE-07 — GET /api/movie/movies/{id} → 200 + DTO con el id solicitado")
    void getMovieById() throws Exception {
        when(movieService.getMovieByMovieId(anyInt())).thenReturn(dto(42, "Detail Movie"));

        mockMvc.perform(get("/api/movie/movies/42"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.movieId").value(42))
                .andExpect(jsonPath("$.movieName").value("Detail Movie"))
                .andExpect(jsonPath("$.directorName").value("Director 42"));
    }
}
